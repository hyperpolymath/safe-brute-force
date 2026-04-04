;;;; SafeBruteForce State Manager
;;;; Manages the state machine for pause/resume functionality using gen_statem

(defmodule sbf_state
  (behaviour gen_statem)
  (export
   ;; API
   (start_link 1)
   (attempt 2)
   (pause 0)
   (resume 0)
   (stop 0)
   (get_status 0)
   (get_stats 0)
   (reset 0)
   ;; gen_statem callbacks
   (callback_mode 0)
   (init 1)
   (running 3)
   (paused 3)
   (waiting_confirmation 3)
   (stopped 3)
   (terminate 3)
   (code_change 4)))

;;; ============================================================
;;; API Functions
;;; ============================================================

(defun start_link (config)
  "Start the state manager with configuration"
  (gen_statem:start_link
   (tuple 'local 'sbf_state_manager)
   'sbf_state
   config
   '()))

(defun attempt (pattern result)
  "Record an attempt with its result"
  (gen_statem:call 'sbf_state_manager (tuple 'attempt pattern result)))

(defun pause ()
  "Manually pause the brute-force operation"
  (gen_statem:call 'sbf_state_manager 'pause))

(defun resume ()
  "Resume after pause"
  (gen_statem:call 'sbf_state_manager 'resume))

(defun stop ()
  "Stop the state manager"
  (gen_statem:stop 'sbf_state_manager))

(defun get_status ()
  "Get current state and basic info"
  (gen_statem:call 'sbf_state_manager 'get_status))

(defun get_stats ()
  "Get detailed statistics"
  (gen_statem:call 'sbf_state_manager 'get_stats))

(defun reset ()
  "Reset counters (useful for testing)"
  (gen_statem:call 'sbf_state_manager 'reset))

;;; ============================================================
;;; gen_statem callbacks
;;; ============================================================

(defun callback_mode () 'state_functions)

(defun init (config)
  "Initialize the state machine"
  (let* ((pause-interval (proplists:get_value 'pause_interval config 25))
         (safety-enabled (proplists:get_value 'safety_enabled config 'true))
         (data (map 'pause_interval pause-interval
                    'safety_enabled safety-enabled
                    'attempt_count 0
                    'success_count 0
                    'failure_count 0
                    'start_time (erlang:system_time 'second)
                    'last_attempt_time 0
                    'current_batch 0
                    'successful_patterns '()
                    'checkpoint_id 'undefined)))
    (tuple 'ok 'running data)))

;;; ============================================================
;;; State: running
;;; ============================================================

(defun running
  ;; Handle attempt recording
  (('call from (tuple 'attempt pattern result) data)
   (let* ((count (+ 1 (maps:get 'attempt_count data)))
          (pause-interval (maps:get 'pause_interval data))
          (safety-enabled (maps:get 'safety_enabled data))
          (should-pause? (and safety-enabled
                              (== 0 (rem count pause-interval))))
          (data1 (maps:put 'attempt_count count data))
          (data2 (maps:put 'last_attempt_time (erlang:system_time 'second) data1))
          (data3 (case result
                   ('success
                    (let ((succ (+ 1 (maps:get 'success_count data2)))
                          (patterns (cons pattern (maps:get 'successful_patterns data2))))
                      (-> data2
                          (maps:put 'success_count succ)
                          (maps:put 'successful_patterns patterns))))
                   ('failure
                    (maps:put 'failure_count
                              (+ 1 (maps:get 'failure_count data2))
                              data2))
                   (_ data2))))
     (if should-pause?
         ;; Transition to waiting_confirmation state
         (tuple 'next_state 'waiting_confirmation data3
                (list (tuple 'reply from (tuple 'ok 'paused count))))
         ;; Stay in running state
         (tuple 'keep_state data3
                (list (tuple 'reply from (tuple 'ok 'running count)))))))

  ;; Handle manual pause
  (('call from 'pause data)
   (tuple 'next_state 'paused data
          (list (tuple 'reply from 'ok))))

  ;; Get status
  (('call from 'get_status data)
   (let ((status (map 'state 'running
                      'attempts (maps:get 'attempt_count data)
                      'successes (maps:get 'success_count data))))
     (tuple 'keep_state_and_data
            (list (tuple 'reply from status)))))

  ;; Get detailed stats
  (('call from 'get_stats data)
   (tuple 'keep_state_and_data
          (list (tuple 'reply from (format-stats data 'running)))))

  ;; Reset counters
  (('call from 'reset data)
   (let ((data1 (-> data
                    (maps:put 'attempt_count 0)
                    (maps:put 'success_count 0)
                    (maps:put 'failure_count 0)
                    (maps:put 'successful_patterns '())
                    (maps:put 'current_batch 0))))
     (tuple 'keep_state data1
            (list (tuple 'reply from 'ok)))))

  ;; Catch-all
  ((event-type event data)
   (handle-common-event event-type event data 'running)))

;;; ============================================================
;;; State: waiting_confirmation
;;; ============================================================

(defun waiting_confirmation
  ;; Handle resume
  (('call from 'resume data)
   (let ((batch (+ 1 (maps:get 'current_batch data)))
         (data1 (maps:put 'current_batch batch data)))
     (io:format "~n[SafeBruteForce] Batch ~p complete. Resuming...~n" (list batch))
     (tuple 'next_state 'running data1
            (list (tuple 'reply from 'ok)))))

  ;; Handle stop
  (('call from 'stop data)
   (tuple 'next_state 'stopped data
          (list (tuple 'reply from 'ok))))

  ;; Handle attempts while waiting (should be queued)
  (('call from (tuple 'attempt _ _) data)
   (tuple 'keep_state_and_data
          (list (tuple 'reply from (tuple 'error 'waiting_confirmation)))))

  ;; Get status
  (('call from 'get_status data)
   (let ((status (map 'state 'waiting_confirmation
                      'attempts (maps:get 'attempt_count data)
                      'successes (maps:get 'success_count data)
                      'message "Paused - call resume/0 to continue")))
     (tuple 'keep_state_and_data
            (list (tuple 'reply from status)))))

  ;; Get stats
  (('call from 'get_stats data)
   (tuple 'keep_state_and_data
          (list (tuple 'reply from (format-stats data 'waiting_confirmation)))))

  ;; Catch-all
  ((event-type event data)
   (handle-common-event event-type event data 'waiting_confirmation)))

;;; ============================================================
;;; State: paused
;;; ============================================================

(defun paused
  ;; Handle resume
  (('call from 'resume data)
   (io:format "[SafeBruteForce] Resuming from manual pause...~n")
   (tuple 'next_state 'running data
          (list (tuple 'reply from 'ok))))

  ;; Already paused
  (('call from 'pause data)
   (tuple 'keep_state_and_data
          (list (tuple 'reply from (tuple 'already 'paused)))))

  ;; Get status
  (('call from 'get_status data)
   (let ((status (map 'state 'paused
                      'attempts (maps:get 'attempt_count data)
                      'successes (maps:get 'success_count data)
                      'message "Manually paused")))
     (tuple 'keep_state_and_data
            (list (tuple 'reply from status)))))

  ;; Get stats
  (('call from 'get_stats data)
   (tuple 'keep_state_and_data
          (list (tuple 'reply from (format-stats data 'paused)))))

  ;; Catch-all
  ((event-type event data)
   (handle-common-event event-type event data 'paused)))

;;; ============================================================
;;; State: stopped
;;; ============================================================

(defun stopped
  ;; Get status
  (('call from 'get_status data)
   (let ((status (map 'state 'stopped
                      'attempts (maps:get 'attempt_count data)
                      'successes (maps:get 'success_count data))))
     (tuple 'keep_state_and_data
            (list (tuple 'reply from status)))))

  ;; Get stats
  (('call from 'get_stats data)
   (tuple 'keep_state_and_data
          (list (tuple 'reply from (format-stats data 'stopped)))))

  ;; Everything else is rejected
  (('call from _ data)
   (tuple 'keep_state_and_data
          (list (tuple 'reply from (tuple 'error 'stopped)))))

  ;; Catch-all
  ((event-type event data)
   (handle-common-event event-type event data 'stopped)))

;;; ============================================================
;;; Common event handler
;;; ============================================================

(defun handle-common-event
  (('call from 'stop data state)
   (tuple 'next_state 'stopped data
          (list (tuple 'reply from 'ok))))
  ((event-type event data state)
   (io:format "[sbf_state] Unhandled event in state ~p: ~p ~p~n"
              (list state event-type event))
   'keep_state_and_data))

;;; ============================================================
;;; Terminate callback
;;; ============================================================

(defun terminate (reason state data)
  (io:format "[sbf_state] Terminating in state ~p. Reason: ~p~n"
             (list state reason))
  'ok)

(defun code_change (_old-vsn state data _extra)
  (tuple 'ok state data))

;;; ============================================================
;;; Helper functions
;;; ============================================================

(defun format-stats (data state)
  "Format comprehensive statistics"
  (let* ((attempts (maps:get 'attempt_count data))
         (successes (maps:get 'success_count data))
         (failures (maps:get 'failure_count data))
         (start-time (maps:get 'start_time data))
         (current-time (erlang:system_time 'second))
         (elapsed (- current-time start-time))
         (rate (if (> elapsed 0)
                   (/ attempts elapsed)
                   0.0))
         (success-rate (if (> attempts 0)
                           (* 100.0 (/ successes attempts))
                           0.0)))
    (map 'state state
         'attempt_count attempts
         'success_count successes
         'failure_count failures
         'successful_patterns (maps:get 'successful_patterns data)
         'elapsed_seconds elapsed
         'attempts_per_second rate
         'success_rate_percent success-rate
         'current_batch (maps:get 'current_batch data)
         'pause_interval (maps:get 'pause_interval data)
         'safety_enabled (maps:get 'safety_enabled data))))
