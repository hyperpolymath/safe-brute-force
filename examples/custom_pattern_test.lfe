;;;; Example: Custom Pattern Generation
;;;; This demonstrates creating custom pattern strategies

(defmodule custom_pattern_test
  (export (run 0) (run_company_passwords 1)))

(defun run ()
  "Run with custom pattern generator"
  (io:format "~n⚠️  Custom Pattern Test Example ⚠️~n~n")

  ;; Custom pattern generator function
  (let ((pattern-generator
         (lambda ()
           ;; Generate passwords based on company name + year
           (let ((company "AcmeCorp")
                 (years (lists:seq 2020 2025)))
             (lists:flatmap
              (lambda (year)
                (list
                 (++ company (integer_to_list year))
                 (++ (string:to_lower company) (integer_to_list year))
                 (++ company "!" (integer_to_list year))
                 (++ company "@" (integer_to_list year))))
              years)))))

    ;; Configuration
    (let ((pattern-config
           (list (tuple 'type 'custom)
                 (tuple 'function pattern-generator)))
          (target-config
           (list (tuple 'type 'function)
                 (tuple 'function (lambda (p) 'false)))))  ; Mock

      (io:format "Generating custom company-based patterns...~n")
      (sbf:run pattern-config target-config))))

(defun run_company_passwords (company-name)
  "Generate common password patterns for a company"
  (let ((generator
         (lambda ()
           (let ((years (lists:seq 2020 2025))
                 (seasons (list "Spring" "Summer" "Fall" "Winter"))
                 (common-suffixes (list "!" "123" "@2024" "#1")))
             ;; Company + Year
             (let ((base-patterns
                    (lists:flatmap
                     (lambda (year)
                       (list
                        (++ company-name (integer_to_list year))
                        (++ (string:to_lower company-name) (integer_to_list year))))
                     years))
                   ;; Company + Suffix
                   (suffix-patterns
                    (lists:flatmap
                     (lambda (suffix)
                       (list
                        (++ company-name suffix)
                        (++ (string:to_lower company-name) suffix)))
                     common-suffixes))
                   ;; Season + Year
                   (season-patterns
                    (lists:flatmap
                     (lambda (season)
                       (lists:map
                        (lambda (year)
                          (++ season (integer_to_list year)))
                        years))
                     seasons)))
               (++ base-patterns suffix-patterns season-patterns))))))
    (let ((pattern-config
           (list (tuple 'type 'custom)
                 (tuple 'function generator)))
          (target-config
           (list (tuple 'type 'mock)
                 (tuple 'expected "notfound"))))
      (sbf:run pattern-config target-config))))

;;; ============================================================
;;; Keyboard Pattern Generator
;;; ============================================================

(defun keyboard_patterns ()
  "Generate common keyboard patterns"
  (list
   ;; QWERTY rows
   "qwerty" "asdfgh" "zxcvbn"
   "qwertyuiop" "asdfghjkl" "zxcvbnm"
   ;; Common sequences
   "qwer" "asdf" "zxcv"
   "1qaz2wsx" "qazwsx" "qwaszx"
   ;; With numbers
   "qwerty123" "asdfgh123"
   ;; Capitalized
   "Qwerty" "Asdfgh" "Zxcvbn"
   ;; With special chars
   "qwerty!" "asdfgh!" "zxcvbn!"))

(defun test_keyboard_patterns ()
  "Test keyboard pattern passwords"
  (let ((patterns (keyboard_patterns))
        (target-config
         (list (tuple 'type 'mock)
               (tuple 'expected "qwerty123"))))
    (sbf:test_custom patterns (lambda (p) 'false))))
