;;;; SafeBruteForce Pattern Generator
;;;; Generates patterns for brute-force attempts (permutations, combinations, wordlists)

(defmodule sbf_patterns
  (export
   ;; Pattern generation strategies
   (charset_combinations 2)
   (charset_combinations 3)
   (sequential_numbers 2)
   (wordlist 1)
   (wordlist_with_mutations 1)
   (wordlist_with_mutations 2)
   (common_passwords 0)
   (date_patterns 1)
   (custom_pattern 1)
   ;; Utility functions
   (estimate_total 2)
   (permutations 1)
   (combinations 2)))

;;; ============================================================
;;; Pattern Generation Strategies
;;; ============================================================

(defun charset_combinations (charset max-length)
  "Generate all combinations from charset up to max-length
   Returns a lazy list (using Erlang generators)"
  (charset_combinations charset 1 max-length))

(defun charset_combinations (charset min-length max-length)
  "Generate all combinations from charset between min-length and max-length"
  (lists:flatmap
   (lambda (len)
     (generate-strings-of-length charset len))
   (lists:seq min-length max-length)))

(defun generate-strings-of-length (charset length)
  "Generate all strings of exact length from charset"
  (case length
    (0 (list ""))
    (_ (let ((char-list (string:to_graphemes charset)))
         (lists:flatmap
          (lambda (c)
            (lists:map
             (lambda (suffix)
               (++ c suffix))
             (generate-strings-of-length charset (- length 1))))
          char-list)))))

(defun sequential_numbers (start end)
  "Generate sequential numbers as strings"
  (lists:map
   (lambda (n)
     (integer_to_list n))
   (lists:seq start end)))

(defun wordlist (filename)
  "Load patterns from a wordlist file"
  (case (file:read_file filename)
    ((tuple 'ok content)
     (let ((lines (binary:split content (binary "\n") '(global))))
       (lists:filter
        (lambda (line)
          (> (byte_size line) 0))
        (lists:map
         (lambda (line)
           (binary_to_list line))
         lines))))
    ((tuple 'error reason)
     (io:format "Error reading wordlist ~p: ~p~n" (list filename reason))
     '())))

(defun wordlist_with_mutations (filename)
  "Load wordlist and apply common mutations"
  (wordlist_with_mutations filename 'standard))

(defun wordlist_with_mutations (filename mutation-level)
  "Load wordlist and apply mutations based on level (minimal, standard, aggressive)"
  (let ((words (wordlist filename)))
    (lists:flatmap
     (lambda (word)
       (apply-mutations word mutation-level))
     words)))

(defun apply-mutations
  ((word 'minimal)
   ;; Just the word and capitalized version
   (list word
         (capitalize word)))

  ((word 'standard)
   ;; Common substitutions and affixes
   (list word
         (capitalize word)
         (++ word "123")
         (++ word "!")
         (++ word "2024")
         (++ word "2025")
         (leet-speak word)))

  ((word 'aggressive)
   ;; All mutations
   (lists:flatten
    (list word
          (capitalize word)
          (string:to_upper word)
          (++ word "123")
          (++ word "!")
          (++ word "?")
          (++ word "2024")
          (++ word "2025")
          (++ "!" word)
          (leet-speak word)
          (reverse-string word)
          (++ word (reverse-string word))))))

(defun leet-speak (word)
  "Apply common leet speak substitutions"
  (lists:map
   (lambda (c)
     (case c
       (#\a #\4)
       (#\e #\3)
       (#\i #\1)
       (#\o #\0)
       (#\s #\5)
       (#\t #\7)
       (_ c)))
   word))

(defun capitalize (word)
  "Capitalize first letter"
  (case word
    ("" "")
    (_ (let ((first (string:slice word 0 1))
             (rest (string:slice word 1)))
         (++ (string:to_upper first) rest)))))

(defun reverse-string (str)
  "Reverse a string"
  (lists:reverse str))

(defun common_passwords ()
  "Return list of common passwords (for testing weak systems)"
  '("password" "123456" "123456789" "12345678" "12345" "1234567"
    "password1" "123123" "1234567890" "000000" "qwerty" "abc123"
    "password123" "111111" "admin" "letmein" "welcome" "monkey"
    "dragon" "master" "sunshine" "princess" "login" "admin123"
    "root" "toor" "pass" "test" "guest" "oracle" "changeme"))

(defun date_patterns (year)
  "Generate common date patterns for a given year"
  (lists:flatmap
   (lambda (month)
     (lists:flatmap
      (lambda (day)
        (let ((m (pad-zero month))
              (d (pad-zero day))
              (y (integer_to_list year))
              (yy (string:slice y 2 2)))
          (list
           ;; MMDDYYYY
           (++ m d y)
           ;; DDMMYYYY
           (++ d m y)
           ;; YYYYMMDD
           (++ y m d)
           ;; MMDDYY
           (++ m d yy)
           ;; DDMMYY
           (++ d m yy)
           ;; MM/DD/YYYY
           (++ m "/" d "/" y)
           ;; DD/MM/YYYY
           (++ d "/" m "/" y))))
      (lists:seq 1 31)))
   (lists:seq 1 12)))

(defun pad-zero (num)
  "Pad number with leading zero if < 10"
  (let ((str (integer_to_list num)))
    (if (< num 10)
        (++ "0" str)
        str)))

(defun custom_pattern (pattern-fn)
  "Generate patterns using a custom function
   pattern-fn should return a list of patterns"
  (pattern-fn))

;;; ============================================================
;;; Utility Functions
;;; ============================================================

(defun estimate_total
  ((type config)
   "Estimate total number of patterns for a given strategy"
   (case type
     ('charset
      (let* ((charset (proplists:get_value 'charset config))
             (min-len (proplists:get_value 'min_length config 1))
             (max-len (proplists:get_value 'max_length config))
             (base (length (string:to_graphemes charset))))
        ;; Sum of base^i for i from min-len to max-len
        (lists:sum
         (lists:map
          (lambda (len)
            (round (math:pow base len)))
          (lists:seq min-len max-len)))))

     ('sequential
      (let ((start (proplists:get_value 'start config))
            (end (proplists:get_value 'end config)))
        (- end start -1)))

     ('wordlist
      (let ((filename (proplists:get_value 'filename config)))
        (length (wordlist filename))))

     ('wordlist_mutations
      (let* ((filename (proplists:get_value 'filename config))
             (level (proplists:get_value 'mutation_level config 'standard))
             (base-count (length (wordlist filename)))
             (multiplier (case level
                          ('minimal 2)
                          ('standard 7)
                          ('aggressive 14)
                          (_ 7))))
        (* base-count multiplier)))

     ('common_passwords
      (length (common_passwords)))

     ('date_patterns
      (* 31 12 8))  ; 31 days * 12 months * 8 format variations

     (_ 'unknown))))

(defun permutations (list)
  "Generate all permutations of a list"
  (case list
    ('() '(()))
    (_ (lists:flatmap
        (lambda (x)
          (let ((rest (lists:delete x list)))
            (lists:map
             (lambda (perm)
               (cons x perm))
             (permutations rest))))
        list))))

(defun combinations (n list)
  "Generate all combinations of n elements from list"
  (cond
    ((== n 0) '(()))
    ((== list '()) '())
    ('true
     (let ((head (car list))
           (tail (cdr list)))
       (++ (lists:map
            (lambda (comb)
              (cons head comb))
            (combinations (- n 1) tail))
           (combinations n tail))))))

;;; ============================================================
;;; Example Pattern Recipes
;;; ============================================================

(defun pin-codes ()
  "Generate all 4-digit PIN codes"
  (generate-strings-of-length "0123456789" 4))

(defun simple-passwords ()
  "Generate simple alphanumeric passwords (a-z, 0-9) length 4-6"
  (charset_combinations "abcdefghijklmnopqrstuvwxyz0123456789" 4 6))

(defun hex-colors ()
  "Generate all possible hex color codes (for web testing)"
  (let ((hex "0123456789abcdef"))
    (lists:map
     (lambda (code)
       (++ "#" code))
     (generate-strings-of-length hex 6))))
