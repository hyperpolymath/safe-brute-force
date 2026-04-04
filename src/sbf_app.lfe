;;;; SafeBruteForce Application
;;;; OTP Application behavior implementation

(defmodule sbf_app
  (behaviour application)
  (export
   (start 2)
   (stop 1)))

(defun start (_type _args)
  "Start the SafeBruteForce application"
  (sbf_output:print_banner)
  (io:format "[sbf_app] Starting SafeBruteForce application...~n")

  ;; Get configuration
  (let ((config (get-app-config)))
    (io:format "[sbf_app] Configuration loaded: ~p~n" (list config))

    ;; Start supervision tree
    (case (sbf_sup:start_link config)
      ((tuple 'ok pid)
       (io:format "[sbf_app] Supervisor started: ~p~n" (list pid))
       (tuple 'ok pid))
      (error
       (io:format "[sbf_app] Failed to start supervisor: ~p~n" (list error))
       error))))

(defun stop (_state)
  "Stop the SafeBruteForce application"
  (io:format "[sbf_app] Stopping SafeBruteForce application...~n")
  'ok)

;;; ============================================================
;;; Internal Functions
;;; ============================================================

(defun get-app-config ()
  "Load application configuration"
  (list
   (tuple 'pause_interval (get-env 'pause_interval 25))
   (tuple 'max_workers (get-env 'max_workers 10))
   (tuple 'request_timeout (get-env 'request_timeout 5000))
   (tuple 'rate_limit (get-env 'rate_limit 100))
   (tuple 'checkpoint_interval (get-env 'checkpoint_interval 100))
   (tuple 'checkpoint_dir (get-env 'checkpoint_dir "priv/checkpoints"))
   (tuple 'safety_enabled (get-env 'safety_enabled 'true))))

(defun get-env (key default)
  "Get environment variable with default"
  (case (application:get_env 'safe_brute_force key)
    ((tuple 'ok value) value)
    ('undefined default)))
