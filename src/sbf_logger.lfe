;;;; SafeBruteForce Logger
;;;; Structured logging for brute-force operations

(defmodule sbf_logger
  (export
   (log 2)
   (log 3)
   (debug 1)
   (info 1)
   (warning 1)
   (error 1)
   (success 1)
   (failure 1)
   (set_level 1)
   (get_level 0)
   (log_to_file 2)))

;;; ============================================================
;;; Logging Levels
;;; ============================================================

(defun level-priority
  (('debug) 0)
  (('info) 1)
  (('warning) 2)
  (('error) 3)
  (('success) 1)
  (('failure) 2))

;;; ============================================================
;;; Logging API
;;; ============================================================

(defun log (level message)
  "Log message at specified level"
  (log level message (map)))

(defun log (level message metadata)
  "Log message with metadata"
  (let ((current-level (get_level))
        (msg-priority (level-priority level))
        (current-priority (level-priority current-level)))
    (when (>= msg-priority current-priority)
      (let ((formatted (format-log-entry level message metadata)))
        (io:format "~s~n" (list formatted))))))

(defun debug (message)
  "Log debug message"
  (log 'debug message))

(defun info (message)
  "Log info message"
  (log 'info message))

(defun warning (message)
  "Log warning message"
  (log 'warning message))

(defun error (message)
  "Log error message"
  (log 'error message))

(defun success (message)
  "Log success message"
  (log 'success message))

(defun failure (message)
  "Log failure message"
  (log 'failure message))

;;; ============================================================
;;; Configuration
;;; ============================================================

(defun set_level (level)
  "Set logging level"
  (application:set_env 'safe_brute_force 'log_level level))

(defun get_level ()
  "Get current logging level"
  (case (application:get_env 'safe_brute_force 'log_level)
    ((tuple 'ok level) level)
    ('undefined 'info)))

;;; ============================================================
;;; File Logging
;;; ============================================================

(defun log_to_file (filename message)
  "Append log message to file"
  (let ((timestamp (format-timestamp (erlang:system_time 'second)))
        (entry (++ "[" timestamp "] " message "\n")))
    (case (file:write_file filename (list_to_binary entry) '(append))
      ('ok 'ok)
      ((tuple 'error reason)
       (io:format "Error writing to log file: ~p~n" (list reason))
       (tuple 'error reason)))))

;;; ============================================================
;;; Formatting
;;; ============================================================

(defun format-log-entry (level message metadata)
  "Format log entry with timestamp and level"
  (let ((timestamp (format-timestamp (erlang:system_time 'second)))
        (level-str (format-level level))
        (meta-str (format-metadata metadata)))
    (++ "[" timestamp "] " level-str " " message meta-str)))

(defun format-level
  (('debug)   "[DEBUG]  ")
  (('info)    "[INFO]   ")
  (('warning) "[WARNING]")
  (('error)   "[ERROR]  ")
  (('success) "[✓]      ")
  (('failure) "[✗]      "))

(defun format-metadata (metadata)
  "Format metadata map as string"
  (if (== (map_size metadata) 0)
      ""
      (let ((pairs (maps:to_list metadata)))
        (++ " | "
            (string:join
             (lists:map
              (lambda ((tuple key value))
                (++ (atom_to_list key) "=" (format-value value)))
              pairs)
             ", ")))))

(defun format-value (value)
  "Format value for logging"
  (lists:flatten (io_lib:format "~p" (list value))))

(defun format-timestamp (seconds)
  "Format Unix timestamp as readable string"
  (let (((tuple (tuple year month day) (tuple hour minute second))
         (calendar:now_to_local_time (tuple (div seconds 1000000)
                                            (rem seconds 1000000)
                                            0))))
    (io_lib:format "~4..0B-~2..0B-~2..0B ~2..0B:~2..0B:~2..0B"
                   (list year month day hour minute second))))

;;; ============================================================
;;; Structured Logging
;;; ============================================================

(defun log_attempt (pattern result metadata)
  "Log a brute-force attempt"
  (case result
    ('success
     (log 'success
          (++ "Successful attempt: " pattern)
          metadata))
    ('failure
     (log 'debug
          (++ "Failed attempt: " pattern)
          metadata))
    (_
     (log 'error
          (++ "Error with pattern: " pattern)
          metadata))))

(defun log_session_start (config)
  "Log session start"
  (log 'info "Starting brute-force session" config))

(defun log_session_end (stats)
  "Log session end with statistics"
  (log 'info "Brute-force session completed" stats))

(defun log_pause ()
  "Log pause event"
  (log 'warning "Session paused - awaiting user confirmation"))

(defun log_resume ()
  "Log resume event"
  (log 'info "Session resumed"))

(defun log_checkpoint (checkpoint-id)
  "Log checkpoint save"
  (log 'info
       "Checkpoint saved"
       (map 'checkpoint_id checkpoint-id)))
