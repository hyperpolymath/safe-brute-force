;;;; SafeBruteForce Progress Tracker
;;;; Track progress and calculate ETA for brute-force operations

(defmodule sbf_progress
  (export
   (new 1)
   (update 2)
   (get_eta 1)
   (get_percent 1)
   (get_rate 1)
   (print 1)
   (format_duration 1)))

;;; ============================================================
;;; Progress Tracker API
;;; ============================================================

(defun new (total)
  "Create new progress tracker"
  (map 'total total
       'current 0
       'start_time (erlang:system_time 'second)
       'last_update (erlang:system_time 'second)
       'last_current 0))

(defun update (progress current)
  "Update progress with current count"
  (let ((now (erlang:system_time 'second)))
    (-> progress
        (maps:put 'current current)
        (maps:put 'last_update now))))

(defun get_eta (progress)
  "Get estimated time remaining in seconds"
  (let* ((total (maps:get 'total progress))
         (current (maps:get 'current progress))
         (start-time (maps:get 'start_time progress))
         (now (erlang:system_time 'second))
         (elapsed (- now start-time))
         (remaining (- total current)))
    (if (or (== current 0) (== elapsed 0))
        'unknown
        (let* ((rate (/ current elapsed))
               (eta (round (/ remaining rate))))
          eta))))

(defun get_percent (progress)
  "Get completion percentage"
  (let ((total (maps:get 'total progress))
        (current (maps:get 'current progress)))
    (if (== total 0)
        100.0
        (* 100.0 (/ current total)))))

(defun get_rate (progress)
  "Get current rate (items per second)"
  (let* ((current (maps:get 'current progress))
         (start-time (maps:get 'start_time progress))
         (now (erlang:system_time 'second))
         (elapsed (- now start-time)))
    (if (== elapsed 0)
        0.0
        (/ current elapsed))))

(defun print (progress)
  "Print progress bar to console"
  (let* ((percent (get_percent progress))
         (eta (get_eta progress))
         (rate (get_rate progress))
         (current (maps:get 'current progress))
         (total (maps:get 'total progress))
         (bar (make-progress-bar percent 50)))
    (io:format "\r~s ~.1f% (~B/~B) | ~.1f/s | ETA: ~s"
               (list bar percent current total rate (format_eta eta)))))

(defun format_duration (seconds)
  "Format duration in human-readable form"
  (cond
    ((< seconds 60)
     (io_lib:format "~Bs" (list seconds)))
    ((< seconds 3600)
     (let ((mins (div seconds 60))
           (secs (rem seconds 60)))
       (io_lib:format "~Bm ~Bs" (list mins secs))))
    ((< seconds 86400)
     (let* ((hours (div seconds 3600))
            (remainder (rem seconds 3600))
            (mins (div remainder 60)))
       (io_lib:format "~Bh ~Bm" (list hours mins))))
    ('true
     (let* ((days (div seconds 86400))
            (remainder (rem seconds 86400))
            (hours (div remainder 3600)))
       (io_lib:format "~Bd ~Bh" (list days hours))))))

;;; ============================================================
;;; Internal Functions
;;; ============================================================

(defun make-progress-bar (percent width)
  "Create ASCII progress bar"
  (let* ((filled (round (* width (/ percent 100.0))))
         (empty (- width filled)))
    (++ "["
        (string:copies "=" filled)
        (string:copies "-" empty)
        "]")))

(defun format_eta
  (('unknown) "unknown")
  ((seconds) (format_duration seconds)))

;;; ============================================================
;;; Advanced Progress Tracking
;;; ============================================================

(defun track_batch (progress batch-size callback)
  "Track progress for batch processing
   Callback is called with updated progress after each batch"
  (let ((current (maps:get 'current progress))
        (new-current (+ current batch-size))
        (updated (update progress new-current)))
    (funcall callback updated)
    updated))

(defun estimate_completion_time (progress)
  "Estimate completion timestamp"
  (case (get_eta progress)
    ('unknown 'unknown)
    (eta
     (let ((now (erlang:system_time 'second)))
       (+ now eta)))))

(defun format_completion_time (progress)
  "Format estimated completion time as timestamp"
  (case (estimate_completion_time progress)
    ('unknown "Unknown")
    (timestamp
     (let (((tuple date time) (calendar:now_to_local_time
                               (tuple (div timestamp 1000000)
                                     (rem timestamp 1000000)
                                     0))))
       (let (((tuple year month day) date)
             ((tuple hour minute second) time))
         (io_lib:format "~4..0B-~2..0B-~2..0B ~2..0B:~2..0B:~2..0B"
                       (list year month day hour minute second)))))))

(defun get_stats (progress)
  "Get comprehensive progress statistics"
  (let* ((total (maps:get 'total progress))
         (current (maps:get 'current progress))
         (start-time (maps:get 'start_time progress))
         (now (erlang:system_time 'second))
         (elapsed (- now start-time))
         (percent (get_percent progress))
         (rate (get_rate progress))
         (eta (get_eta progress)))
    (map 'total total
         'current current
         'remaining (- total current)
         'percent percent
         'elapsed_seconds elapsed
         'rate_per_second rate
         'eta_seconds eta
         'eta_formatted (format_eta eta)
         'completion_time (format_completion_time progress))))
