;;;; Example: HTTP Login Brute Force Test
;;;; This demonstrates testing a web login form

(defmodule http_login_test
  (export (run 0) (run 1)))

(defun run ()
  "Run with default test configuration"
  (run "priv/wordlists/test-wordlist.txt"))

(defun run (wordlist-file)
  "Test HTTP login endpoint with wordlist
   NOTE: Replace URL with your own authorized test system!"
  (io:format "~n⚠️  HTTP Login Test Example ⚠️~n")
  (io:format "This is a demonstration only.~n")
  (io:format "Replace the URL with your authorized test system!~n~n")

  ;; Configuration
  (let* ((target-url "http://localhost:8080/login")  ; CHANGE THIS
         (username "testuser")                        ; CHANGE THIS
         (pattern-config
          (list (tuple 'type 'wordlist)
                (tuple 'filename wordlist-file)
                (tuple 'mutations 'standard)))  ; Apply common mutations
         (target-config
          (list (tuple 'type 'http)
                (tuple 'url target-url)
                (tuple 'method 'post)
                (tuple 'username username)
                (tuple 'username_field "username")
                (tuple 'password_field "password")
                ;; Define success/failure patterns
                (tuple 'success_pattern "Dashboard")
                (tuple 'failure_pattern "Invalid credentials")
                ;; Optional: custom headers
                (tuple 'headers (list (tuple "X-Custom-Header" "test"))))))

    ;; Run the test
    (io:format "Starting HTTP brute-force test...~n")
    (io:format "Target: ~s~n" (list target-url))
    (io:format "Username: ~s~n" (list username))
    (io:format "Wordlist: ~s~n~n" (list wordlist-file))

    (sbf:run pattern-config target-config)))

;;; ============================================================
;;; Advanced Example: JSON API
;;; ============================================================

(defun test_json_api (api-url username wordlist-file)
  "Test JSON API endpoint"
  (let ((pattern-config
         (list (tuple 'type 'wordlist)
               (tuple 'filename wordlist-file)))
        (target-config
         (list (tuple 'type 'http)
               (tuple 'url api-url)
               (tuple 'method 'post)
               (tuple 'username username)
               (tuple 'username_field "user")
               (tuple 'password_field "pass")
               (tuple 'body_format 'json)  ; Use JSON instead of urlencoded
               (tuple 'success_pattern "\"authenticated\":true")
               (tuple 'headers (list (tuple "Content-Type" "application/json")
                                    (tuple "Accept" "application/json"))))))
    (sbf:run pattern-config target-config)))
