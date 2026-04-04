;;;; SafeBruteForce Executor
;;;; Manages worker pool and executes brute-force attempts

(defmodule sbf_executor
  (behaviour gen_server)
  (export
   ;; API
   (start_link 1)
   (execute_batch 2)
   (stop 0)
   (get_worker_status 0)
   ;; gen_server callbacks
   (init 1)
   (handle_call 3)
   (handle_cast 2)
   (handle_info 2)
   (terminate 2)
   (code_change 3)))

;;; ============================================================
;;; API Functions
;;; ============================================================

(defun start_link (config)
  "Start the executor with configuration"
  (gen_server:start_link
   (tuple 'local 'sbf_executor)
   'sbf_executor
   config
   '()))

(defun execute_batch (patterns target-config)
  "Execute a batch of patterns against the target
   Returns when batch is complete or paused"
  (gen_server:call 'sbf_executor
                   (tuple 'execute_batch patterns target-config)
                   'infinity))

(defun stop ()
  "Stop the executor"
  (gen_server:stop 'sbf_executor))

(defun get_worker_status ()
  "Get current worker pool status"
  (gen_server:call 'sbf_executor 'get_worker_status))

;;; ============================================================
;;; gen_server callbacks
;;; ============================================================

(defun init (config)
  "Initialize the executor"
  (let* ((max-workers (proplists:get_value 'max_workers config 10))
         (timeout (proplists:get_value 'request_timeout config 5000))
         (rate-limit (proplists:get_value 'rate_limit config 100))
         (state (map 'max_workers max-workers
                     'timeout timeout
                     'rate_limit rate-limit
                     'active_workers 0
                     'worker_pids '())))
    (tuple 'ok state)))

(defun handle_call
  ;; Execute batch of patterns
  (((tuple 'execute_batch patterns target-config) from state)
   (let ((self-pid (self)))
     ;; Spawn async worker to handle batch
     (spawn_link
      (lambda ()
        (let ((result (execute-patterns patterns target-config state)))
          (gen_server:reply from result))))
     (tuple 'noreply state)))

  ;; Get worker status
  (('get_worker_status from state)
   (let ((status (map 'active_workers (maps:get 'active_workers state)
                      'max_workers (maps:get 'max_workers state)
                      'rate_limit (maps:get 'rate_limit state))))
     (tuple 'reply status state)))

  ;; Catch-all
  ((request from state)
   (io:format "[sbf_executor] Unknown call: ~p~n" (list request))
   (tuple 'reply (tuple 'error 'unknown_request) state)))

(defun handle_cast (msg state)
  (io:format "[sbf_executor] Unknown cast: ~p~n" (list msg))
  (tuple 'noreply state))

(defun handle_info (info state)
  (io:format "[sbf_executor] Unknown info: ~p~n" (list info))
  (tuple 'noreply state))

(defun terminate (reason state)
  (io:format "[sbf_executor] Terminating. Reason: ~p~n" (list reason))
  'ok)

(defun code_change (_old-vsn state _extra)
  (tuple 'ok state))

;;; ============================================================
;;; Internal Functions
;;; ============================================================

(defun execute-patterns (patterns target-config state)
  "Execute all patterns in the batch"
  (let* ((rate-limit (maps:get 'rate_limit state))
         (delay-ms (calculate-delay rate-limit))
         (target-type (proplists:get_value 'type target-config))
         (results (lists:map
                   (lambda (pattern)
                     ;; Rate limiting delay
                     (when (> delay-ms 0)
                       (timer:sleep delay-ms))
                     ;; Execute single attempt
                     (let ((result (execute-single pattern target-type target-config state)))
                       ;; Record in state manager
                       (case result
                         ((tuple 'ok 'success data)
                          (sbf_state:attempt pattern 'success)
                          (io:format "[SUCCESS] Pattern: ~s -> ~p~n" (list pattern data))
                          (tuple pattern 'success data))
                         ((tuple 'ok 'failure reason)
                          (sbf_state:attempt pattern 'failure)
                          (tuple pattern 'failure reason))
                         ((tuple 'error reason)
                          (sbf_state:attempt pattern 'failure)
                          (tuple pattern 'error reason)))))
                   patterns)))
    (tuple 'ok results)))

(defun calculate-delay (rate-limit)
  "Calculate delay in ms between requests to maintain rate limit"
  (if (> rate-limit 0)
      (round (/ 1000.0 rate-limit))
      0))

(defun execute-single
  ;; HTTP/HTTPS target
  ((pattern 'http target-config state)
   (execute-http pattern target-config state))

  ;; Custom function target
  ((pattern 'function target-config state)
   (let ((test-fn (proplists:get_value 'function target-config)))
     (try
       (case (funcall test-fn pattern)
         ('true (tuple 'ok 'success pattern))
         ('false (tuple 'ok 'failure 'no_match))
         (result (tuple 'ok 'success result)))
       (catch
         ((tuple type error)
          (tuple 'error (tuple type error)))))))

  ;; Mock target (for testing)
  ((pattern 'mock target-config state)
   (let ((expected (proplists:get_value 'expected target-config)))
     (if (== pattern expected)
         (tuple 'ok 'success pattern)
         (tuple 'ok 'failure 'no_match))))

  ;; SSH target
  ((pattern 'ssh target-config state)
   (execute-ssh pattern target-config state))

  ;; Unknown target type
  ((pattern target-type _ _)
   (tuple 'error (tuple 'unknown_target_type target-type))))

(defun execute-http (pattern target-config state)
  "Execute HTTP/HTTPS brute-force attempt"
  (let* ((url (proplists:get_value 'url target-config))
         (method (proplists:get_value 'method target-config 'post))
         (username (proplists:get_value 'username target-config))
         (password-field (proplists:get_value 'password_field target-config "password"))
         (username-field (proplists:get_value 'username_field target-config "username"))
         (success-pattern (proplists:get_value 'success_pattern target-config))
         (failure-pattern (proplists:get_value 'failure_pattern target-config))
         (timeout (maps:get 'timeout state)))
    (try
      (let* ((body (build-http-body username-field username
                                    password-field pattern
                                    target-config))
             (headers (build-http-headers target-config))
             (response (case method
                        ('post
                         (lhttpc:request url 'post headers body timeout '()))
                        ('get
                         (lhttpc:request (++ url "?" body) 'get headers timeout '())))))
        (case response
          ((tuple 'ok (tuple (tuple status-code _) response-headers response-body))
           (analyze-http-response status-code response-body
                                 success-pattern failure-pattern pattern))
          ((tuple 'error reason)
           (tuple 'error reason))))
      (catch
        ((tuple type error)
         (tuple 'error (tuple type error)))))))

(defun build-http-body (username-field username password-field password target-config)
  "Build HTTP request body"
  (let ((format (proplists:get_value 'body_format target-config 'urlencoded))
        (extra-fields (proplists:get_value 'extra_fields target-config '())))
    (case format
      ('urlencoded
       (let ((params (++ (list (tuple username-field username)
                              (tuple password-field password))
                        extra-fields)))
         (encode-urlencoded params)))
      ('json
       (let ((map (maps:from_list
                   (++ (list (tuple username-field username)
                            (tuple password-field password))
                       extra-fields))))
         (jsx:encode map)))
      (_ ""))))

(defun encode-urlencoded (params)
  "Encode parameters as URL-encoded string"
  (string:join
   (lists:map
    (lambda ((tuple key value))
      (++ (url-encode (to-string key))
          "="
          (url-encode (to-string value))))
    params)
   "&"))

(defun url-encode (str)
  "URL encode a string"
  (binary_to_list
   (cow_qs:urlencode (list_to_binary str))))

(defun to-string
  ((x) (when (is_atom x))
   (atom_to_list x))
  ((x) (when (is_list x))
   x)
  ((x) (when (is_binary x))
   (binary_to_list x))
  ((x) (when (is_integer x))
   (integer_to_list x)))

(defun build-http-headers (target-config)
  "Build HTTP headers"
  (let ((custom-headers (proplists:get_value 'headers target-config '()))
        (body-format (proplists:get_value 'body_format target-config 'urlencoded)))
    (++ custom-headers
        (list (tuple "User-Agent" "SafeBruteForce/0.1.0 (Authorized Testing)")
              (case body-format
                ('json (tuple "Content-Type" "application/json"))
                (_ (tuple "Content-Type" "application/x-www-form-urlencoded")))))))

(defun analyze-http-response (status-code body success-pattern failure-pattern pattern)
  "Analyze HTTP response to determine success/failure"
  (let ((body-str (if (is_binary body)
                      (binary_to_list body)
                      body)))
    (cond
      ;; Check success pattern
      ((and success-pattern
            (string:find body-str success-pattern))
       (tuple 'ok 'success (map 'pattern pattern
                                'status status-code
                                'matched success-pattern)))

      ;; Check failure pattern
      ((and failure-pattern
            (string:find body-str failure-pattern))
       (tuple 'ok 'failure (map 'pattern pattern
                                'status status-code
                                'matched failure-pattern)))

      ;; Check HTTP status code
      ((or (== status-code 200)
           (== status-code 302)
           (== status-code 301))
       (tuple 'ok 'success (map 'pattern pattern
                                'status status-code)))

      ;; Default to failure
      ('true
       (tuple 'ok 'failure (map 'status status-code))))))

(defun execute-ssh (pattern target-config state)
  "Execute SSH brute-force attempt
   NOTE: Requires ssh library, placeholder for now"
  (tuple 'error 'ssh_not_implemented))
