;;;; Example: PIN Code Brute Force Test
;;;; This demonstrates testing all possible 4-digit PIN codes

(defmodule pin_code_test
  (export (run 0) (run_custom 1)))

(defun run ()
  "Test all 4-digit PIN codes against mock validator"
  (io:format "~n⚠️  PIN Code Test Example ⚠️~n")
  (io:format "Testing all 10,000 possible 4-digit PIN codes~n")
  (io:format "This is for demonstration purposes only!~n~n")

  ;; Mock PIN validator (replace with real system)
  (let ((secret-pin "1234")
        (validator (lambda (pin)
                    (== pin secret-pin))))

    ;; Configuration
    (let ((pattern-config
           (list (tuple 'type 'charset)
                 (tuple 'charset "0123456789")
                 (tuple 'min_length 4)
                 (tuple 'max_length 4)))
          (target-config
           (list (tuple 'type 'function)
                 (tuple 'function validator))))

      (io:format "Starting PIN brute-force test...~n")
      (io:format "Total combinations: 10,000~n")
      (io:format "Pause interval: every 25 attempts~n~n")

      ;; Run the test
      (sbf:run pattern-config target-config))))

(defun run_custom (validator-fn)
  "Test with custom PIN validator function"
  (let ((pattern-config
         (list (tuple 'type 'charset)
               (tuple 'charset "0123456789")
               (tuple 'min_length 4)
               (tuple 'max_length 4)))
        (target-config
         (list (tuple 'type 'function)
               (tuple 'function validator-fn))))
    (sbf:run pattern-config target-config)))

;;; ============================================================
;;; Advanced Examples
;;; ============================================================

(defun test_6digit_pins ()
  "Test 6-digit PIN codes (1,000,000 combinations)"
  (io:format "⚠️  WARNING: This will test 1,000,000 combinations!~n")
  (let ((validator (lambda (pin) 'false))  ; Mock validator
        (pattern-config
         (list (tuple 'type 'charset)
               (tuple 'charset "0123456789")
               (tuple 'min_length 6)
               (tuple 'max_length 6)))
        (target-config
         (list (tuple 'type 'function)
               (tuple 'function validator))))
    (sbf:run pattern-config target-config)))

(defun test_date_based_pins (year)
  "Test date-based PIN patterns for a given year"
  (let ((patterns (sbf_patterns:date_patterns year))
        (validator (lambda (pin) 'false)))  ; Mock validator
    (io:format "Testing ~B date-based patterns for year ~B~n"
               (list (length patterns) year))
    (sbf:test_custom patterns validator)))
