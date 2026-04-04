;;;; SafeBruteForce Rate Limiter
;;;; Token bucket algorithm for controlling request rate

(defmodule sbf_rate_limiter
  (behaviour gen_server)
  (export
   ;; API
   (start_link 1)
   (acquire 0)
   (acquire 1)
   (set_rate 1)
   (get_rate 0)
   (stop 0)
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

(defun start_link (rate-limit)
  "Start rate limiter with requests per second limit"
  (gen_server:start_link
   (tuple 'local 'sbf_rate_limiter)
   'sbf_rate_limiter
   rate-limit
   '()))

(defun acquire ()
  "Acquire a token (blocking until available)"
  (acquire 1))

(defun acquire (count)
  "Acquire N tokens (blocking until available)"
  (gen_server:call 'sbf_rate_limiter (tuple 'acquire count) 'infinity))

(defun set_rate (new-rate)
  "Update rate limit"
  (gen_server:call 'sbf_rate_limiter (tuple 'set_rate new-rate)))

(defun get_rate ()
  "Get current rate limit"
  (gen_server:call 'sbf_rate_limiter 'get_rate))

(defun stop ()
  "Stop rate limiter"
  (gen_server:stop 'sbf_rate_limiter))

;;; ============================================================
;;; gen_server callbacks
;;; ============================================================

(defun init (rate-limit)
  "Initialize token bucket"
  (let ((state (map 'rate rate-limit
                    'tokens rate-limit
                    'max_tokens rate-limit
                    'last_refill (erlang:system_time 'millisecond))))
    ;; Start refill timer (every 100ms)
    (erlang:send_after 100 (self) 'refill)
    (tuple 'ok state)))

(defun handle_call
  ;; Acquire tokens
  (((tuple 'acquire count) from state)
   (let* ((state1 (refill-tokens state))
          (tokens (maps:get 'tokens state1)))
     (if (>= tokens count)
         ;; Enough tokens available
         (let ((state2 (maps:put 'tokens (- tokens count) state1)))
           (tuple 'reply 'ok state2))
         ;; Not enough tokens - wait a bit
         (begin
           (timer:sleep (calculate-wait-time count (maps:get 'rate state1)))
           (handle_call (tuple 'acquire count) from (refill-tokens state1))))))

  ;; Set rate
  (((tuple 'set_rate new-rate) _from state)
   (let ((state1 (-> state
                     (maps:put 'rate new-rate)
                     (maps:put 'max_tokens new-rate))))
     (tuple 'reply 'ok state1)))

  ;; Get rate
  (('get_rate _from state)
   (tuple 'reply (maps:get 'rate state) state))

  ;; Catch-all
  ((request _from state)
   (tuple 'reply (tuple 'error 'unknown_request) state)))

(defun handle_cast (_msg state)
  (tuple 'noreply state))

(defun handle_info
  ;; Refill timer
  (('refill state)
   (let ((state1 (refill-tokens state)))
     ;; Schedule next refill
     (erlang:send_after 100 (self) 'refill)
     (tuple 'noreply state1)))

  ;; Catch-all
  ((_info state)
   (tuple 'noreply state)))

(defun terminate (_reason _state)
  'ok)

(defun code_change (_old-vsn state _extra)
  (tuple 'ok state))

;;; ============================================================
;;; Internal Functions
;;; ============================================================

(defun refill-tokens (state)
  "Refill tokens based on elapsed time (token bucket algorithm)"
  (let* ((now (erlang:system_time 'millisecond))
         (last-refill (maps:get 'last_refill state))
         (elapsed-ms (- now last-refill))
         (rate (maps:get 'rate state))
         (max-tokens (maps:get 'max_tokens state))
         (current-tokens (maps:get 'tokens state))
         ;; Calculate tokens to add based on elapsed time
         (tokens-to-add (/ (* rate elapsed-ms) 1000.0))
         (new-tokens (min max-tokens (+ current-tokens tokens-to-add))))
    (-> state
        (maps:put 'tokens new-tokens)
        (maps:put 'last_refill now))))

(defun calculate-wait-time (needed-tokens rate)
  "Calculate milliseconds to wait for tokens"
  (round (/ (* needed-tokens 1000.0) rate)))

(defun min (a b)
  (if (< a b) a b))
