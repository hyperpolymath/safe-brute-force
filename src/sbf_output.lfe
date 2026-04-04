;;;; SafeBruteForce Output Manager
;;;; Handles result aggregation, filtering, and clean output formatting

(defmodule sbf_output
  (export
   (format_results 1)
   (format_results 2)
   (filter_results 2)
   (save_results 2)
   (print_summary 1)
   (print_progress 2)
   (print_banner 0)))

;;; ============================================================
;;; Output Formatting
;;; ============================================================

(defun format_results (results)
  "Format results with default settings (successes only)"
  (format_results results 'successes_only))

(defun format_results
  ((results 'successes_only)
   "Show only successful attempts"
   (let ((successes (filter_results results 'success)))
     (lists:map #'format-single-result/1 successes)))

  ((results 'failures_only)
   "Show only failed attempts"
   (let ((failures (filter_results results 'failure)))
     (lists:map #'format-single-result/1 failures)))

  ((results 'all)
   "Show all attempts"
   (lists:map #'format-single-result/1 results))

  ((results 'summary)
   "Show summary statistics"
   (let* ((total (length results))
          (successes (length (filter_results results 'success)))
          (failures (- total successes))
          (success-rate (if (> total 0)
                            (* 100.0 (/ successes total))
                            0.0)))
     (list
      (map 'total_attempts total
           'successes successes
           'failures failures
           'success_rate success-rate)))))

(defun format-single-result
  (((tuple pattern 'success data))
   (map 'pattern pattern
        'result 'success
        'data data
        'formatted (++ "[✓] " pattern " -> SUCCESS")))

  (((tuple pattern 'failure reason))
   (map 'pattern pattern
        'result 'failure
        'reason reason
        'formatted (++ "[✗] " pattern " -> FAILED")))

  (((tuple pattern 'error reason))
   (map 'pattern pattern
        'result 'error
        'reason reason
        'formatted (++ "[ERROR] " pattern " -> " (format-term reason)))))

(defun filter_results
  ((results 'success)
   "Filter for successful results only"
   (lists:filter
    (lambda (result)
      (case result
        ((tuple _ 'success _) 'true)
        (_ 'false)))
    results))

  ((results 'failure)
   "Filter for failed results"
   (lists:filter
    (lambda (result)
      (case result
        ((tuple _ 'failure _) 'true)
        ((tuple _ 'error _) 'true)
        (_ 'false)))
    results))

  ((results 'error)
   "Filter for errors only"
   (lists:filter
    (lambda (result)
      (case result
        ((tuple _ 'error _) 'true)
        (_ 'false)))
    results)))

;;; ============================================================
;;; File Output
;;; ============================================================

(defun save_results (results filename)
  "Save results to a file"
  (let* ((formatted (format_results results 'all))
         (content (format-results-for-file formatted)))
    (case (file:write_file filename (list_to_binary content))
      ('ok
       (tuple 'ok (map 'filename filename
                       'total_results (length results))))
      ((tuple 'error reason)
       (tuple 'error (map 'filename filename
                          'reason reason))))))

(defun format-results-for-file (results)
  "Format results as text for file output"
  (let ((timestamp (format-timestamp (erlang:system_time 'second)))
        (header (++ "SafeBruteForce Results\n"
                   "Generated: " timestamp "\n"
                   "=====================================\n\n"))
        (body (string:join
               (lists:map
                (lambda (result)
                  (maps:get 'formatted result))
                results)
               "\n"))
        (footer "\n\n=====================================\n"))
    (++ header body footer)))

;;; ============================================================
;;; Console Output
;;; ============================================================

(defun print_summary (stats)
  "Print comprehensive summary to console"
  (let ((state (maps:get 'state stats))
        (attempts (maps:get 'attempt_count stats))
        (successes (maps:get 'success_count stats))
        (failures (maps:get 'failure_count stats))
        (elapsed (maps:get 'elapsed_seconds stats))
        (rate (maps:get 'attempts_per_second stats))
        (success-rate (maps:get 'success_rate_percent stats))
        (patterns (maps:get 'successful_patterns stats)))
    (io:format "~n")
    (io:format "╔════════════════════════════════════════════════════╗~n")
    (io:format "║       SafeBruteForce - Session Summary            ║~n")
    (io:format "╠════════════════════════════════════════════════════╣~n")
    (io:format "║ State:           ~-30s ║~n" (list state))
    (io:format "║ Total Attempts:  ~-30B ║~n" (list attempts))
    (io:format "║ Successes:       ~-30B ║~n" (list successes))
    (io:format "║ Failures:        ~-30B ║~n" (list failures))
    (io:format "║ Elapsed Time:    ~-30B seconds ║~n" (list elapsed))
    (io:format "║ Attempts/sec:    ~-30.2f ║~n" (list rate))
    (io:format "║ Success Rate:    ~-30.2f% ║~n" (list success-rate))
    (io:format "╚════════════════════════════════════════════════════╝~n")
    (when (> (length patterns) 0)
      (io:format "~nSuccessful Patterns:~n")
      (lists:foreach
       (lambda (pattern)
         (io:format "  ✓ ~s~n" (list pattern)))
       (lists:reverse patterns)))
    (io:format "~n")))

(defun print_progress (current total)
  "Print progress bar"
  (let* ((percent (if (> total 0)
                      (/ (* current 100.0) total)
                      0.0))
         (bar-width 50)
         (filled (round (/ (* percent bar-width) 100.0)))
         (empty (- bar-width filled))
         (bar (++ (string:chars #\═ filled)
                  (string:chars #\─ empty))))
    (io:format "\r[~s] ~.1f% (~B/~B)" (list bar percent current total))))

(defun print_banner ()
  "Print SafeBruteForce banner"
  (io:format "~n")
  (io:format "  ███████╗ █████╗ ███████╗███████╗    ██████╗ ███████╗~n")
  (io:format "  ██╔════╝██╔══██╗██╔════╝██╔════╝    ██╔══██╗██╔════╝~n")
  (io:format "  ███████╗███████║█████╗  █████╗      ██████╔╝█████╗  ~n")
  (io:format "  ╚════██║██╔══██║██╔══╝  ██╔══╝      ██╔══██╗██╔══╝  ~n")
  (io:format "  ███████║██║  ██║██║     ███████╗    ██████╔╝██║     ~n")
  (io:format "  ╚══════╝╚═╝  ╚═╝╚═╝     ╚══════╝    ╚═════╝ ╚═╝     ~n")
  (io:format "~n")
  (io:format "  SafeBruteForce v0.1.0 - Controlled Ethical Testing~n")
  (io:format "  ⚠️  For Authorized Security Testing Only ⚠️~n")
  (io:format "~n"))

;;; ============================================================
;;; Helper Functions
;;; ============================================================

(defun format-term (term)
  "Format any term as string"
  (lists:flatten (io_lib:format "~p" (list term))))

(defun format-timestamp (seconds)
  "Format Unix timestamp as readable string"
  (let (((tuple (tuple year month day) (tuple hour minute second))
         (calendar:now_to_local_time (tuple (div seconds 1000000)
                                            (rem seconds 1000000)
                                            0))))
    (io_lib:format "~4..0B-~2..0B-~2..0B ~2..0B:~2..0B:~2..0B"
                   (list year month day hour minute second))))

;;; ============================================================
;;; Color Output (if terminal supports it)
;;; ============================================================

(defun colorize
  ((text 'green)
   (++ "\e[32m" text "\e[0m"))
  ((text 'red)
   (++ "\e[31m" text "\e[0m"))
  ((text 'yellow)
   (++ "\e[33m" text "\e[0m"))
  ((text 'blue)
   (++ "\e[34m" text "\e[0m"))
  ((text 'cyan)
   (++ "\e[36m" text "\e[0m"))
  ((text _)
   text))

(defun print_success (message)
  "Print success message in green"
  (io:format "~s~n" (list (colorize message 'green))))

(defun print_error (message)
  "Print error message in red"
  (io:format "~s~n" (list (colorize message 'red))))

(defun print_warning (message)
  "Print warning message in yellow"
  (io:format "~s~n" (list (colorize message 'yellow))))

(defun print_info (message)
  "Print info message in cyan"
  (io:format "~s~n" (list (colorize message 'cyan))))
