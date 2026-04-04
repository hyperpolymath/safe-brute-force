;;;; SafeBruteForce Main Entry Point
;;;; High-level API for running brute-force operations

(defmodule sbf
  (export
   ;; Main API
   (start 0)
   (stop 0)
   (run 1)
   (run 2)
   (run_async 2)
   ;; Convenience functions
   (test_http 3)
   (test_wordlist 2)
   (test_pins 1)
   (test_custom 2)
   ;; Status and control
   (pause 0)
   (resume 0)
   (status 0)
   (stats 0)
   ;; Checkpoint operations
   (save_checkpoint 0)
   (save_checkpoint 1)
   (load_checkpoint 1)
   (list_checkpoints 0)))

;;; ============================================================
;;; Application Control
;;; ============================================================

(defun start ()
  "Start the SafeBruteForce application"
  (application:ensure_all_started 'safe_brute_force))

(defun stop ()
  "Stop the SafeBruteForce application"
  (application:stop 'safe_brute_force))

;;; ============================================================
;;; Main Brute-Force API
;;; ============================================================

(defun run (config)
  "Run brute-force operation with configuration map
   Config should contain:
   - pattern_type: 'charset | 'wordlist | 'sequential | 'custom
   - pattern_config: Configuration for pattern generation
   - target_config: Configuration for target testing"
  (run config (map)))

(defun run (pattern-config target-config)
  "Run brute-force operation synchronously
   Returns results when complete"
  (start)
  (sbf_output:print_banner)
  (let* ((patterns (generate-patterns pattern-config))
         (total (length patterns))
         (batch-size (get-batch-size)))
    (io:format "[SafeBruteForce] Generated ~B patterns~n" (list total))
    (io:format "[SafeBruteForce] Batch size: ~B~n" (list batch-size))
    (io:format "[SafeBruteForce] ⚠️  Pause every ~B attempts (safety enabled)~n"
               (list (get-pause-interval)))
    (io:format "~n")

    ;; Process patterns in batches
    (process-batches patterns target-config batch-size)

    ;; Print final summary
    (let ((stats (sbf_state:get_stats)))
      (sbf_output:print_summary stats)
      stats)))

(defun run_async (pattern-config target-config)
  "Run brute-force operation asynchronously
   Returns immediately with process ID"
  (start)
  (spawn
   (lambda ()
     (run pattern-config target-config))))

;;; ============================================================
;;; Convenience Functions
;;; ============================================================

(defun test_http (url username wordlist-file)
  "Test HTTP endpoint with username and wordlist
   Example: (sbf:test_http \"http://example.com/login\" \"admin\" \"wordlist.txt\")"
  (let ((pattern-config
         (list (tuple 'type 'wordlist)
               (tuple 'filename wordlist-file)))
        (target-config
         (list (tuple 'type 'http)
               (tuple 'url url)
               (tuple 'method 'post)
               (tuple 'username username)
               (tuple 'username_field "username")
               (tuple 'password_field "password")
               (tuple 'success_pattern "Welcome")
               (tuple 'failure_pattern "Invalid credentials"))))
    (run pattern-config target-config)))

(defun test_wordlist (wordlist-file test-fn)
  "Test patterns from wordlist using custom function
   Example: (sbf:test_wordlist \"passwords.txt\" (lambda (p) (== p \"secret\")))"
  (let ((pattern-config
         (list (tuple 'type 'wordlist)
               (tuple 'filename wordlist-file)))
        (target-config
         (list (tuple 'type 'function)
               (tuple 'function test-fn))))
    (run pattern-config target-config)))

(defun test_pins (test-fn)
  "Test all 4-digit PIN codes using custom function
   Example: (sbf:test_pins (lambda (p) (validate-pin p)))"
  (let ((pattern-config
         (list (tuple 'type 'charset)
               (tuple 'charset "0123456789")
               (tuple 'min_length 4)
               (tuple 'max_length 4)))
        (target-config
         (list (tuple 'type 'function)
               (tuple 'function test-fn))))
    (io:format "⚠️  Testing 10,000 PIN codes. This will take a while.~n")
    (run pattern-config target-config)))

(defun test_custom (pattern-list test-fn)
  "Test custom pattern list using custom function"
  (let ((target-config
         (list (tuple 'type 'function)
               (tuple 'function test-fn))))
    (process-batches pattern-list target-config (get-batch-size))))

;;; ============================================================
;;; Status and Control
;;; ============================================================

(defun pause ()
  "Manually pause the brute-force operation"
  (sbf_state:pause))

(defun resume ()
  "Resume the brute-force operation"
  (sbf_state:resume))

(defun status ()
  "Get current status"
  (sbf_state:get_status))

(defun stats ()
  "Get detailed statistics"
  (sbf_state:get_stats))

;;; ============================================================
;;; Checkpoint Operations
;;; ============================================================

(defun save_checkpoint ()
  "Save current state to checkpoint"
  (save_checkpoint 'default))

(defun save_checkpoint (session-name)
  "Save current state to named checkpoint"
  (let ((state (sbf_state:get_stats)))
    (sbf_checkpoint:save session-name state)))

(defun load_checkpoint (checkpoint-id)
  "Load state from checkpoint"
  (sbf_checkpoint:restore checkpoint-id))

(defun list_checkpoints ()
  "List all available checkpoints"
  (sbf_checkpoint:list_checkpoints))

;;; ============================================================
;;; Internal Functions
;;; ============================================================

(defun generate-patterns (config)
  "Generate patterns based on configuration"
  (let ((type (proplists:get_value 'type config)))
    (case type
      ('charset
       (let ((charset (proplists:get_value 'charset config))
             (min-len (proplists:get_value 'min_length config 1))
             (max-len (proplists:get_value 'max_length config)))
         (sbf_patterns:charset_combinations charset min-len max-len)))

      ('wordlist
       (let ((filename (proplists:get_value 'filename config))
             (mutations (proplists:get_value 'mutations config 'false)))
         (if mutations
             (sbf_patterns:wordlist_with_mutations filename)
             (sbf_patterns:wordlist filename))))

      ('sequential
       (let ((start (proplists:get_value 'start config))
             (end (proplists:get_value 'end config)))
         (sbf_patterns:sequential_numbers start end)))

      ('common
       (sbf_patterns:common_passwords))

      ('custom
       (let ((pattern-fn (proplists:get_value 'function config)))
         (funcall pattern-fn)))

      (_ (begin
           (io:format "Error: Unknown pattern type ~p~n" (list type))
           '())))))

(defun process-batches (patterns target-config batch-size)
  "Process patterns in batches with pause mechanism"
  (let ((batches (partition-list patterns batch-size)))
    (process-batch-list batches target-config 1 (length batches))))

(defun process-batch-list
  (('() _ _ _)
   'ok)
  (((cons batch rest) target-config current total)
   (sbf_output:print_progress (* current batch-size) (* total batch-size))
   (case (sbf_executor:execute_batch batch target-config)
     ((tuple 'ok _results)
      ;; Check if we need to wait for user confirmation
      (case (sbf_state:get_status)
        ((map 'state 'waiting_confirmation)
         (io:format "~n~n")
         (io:format "╔════════════════════════════════════════════════╗~n")
         (io:format "║  🛑 PAUSED - Safety Checkpoint                 ║~n")
         (io:format "║  Completed ~B attempts                          ~n" (list (* current batch-size)))
         (io:format "║  Call (sbf:resume) to continue                 ║~n")
         (io:format "║  Call (sbf:stats) to see results               ║~n")
         (io:format "╚════════════════════════════════════════════════╝~n")
         (io:format "~n")
         ;; Wait for resume
         (wait-for-resume)
         (process-batch-list rest target-config (+ current 1) total))
        (_
         (process-batch-list rest target-config (+ current 1) total))))
     ((tuple 'error reason)
      (io:format "~nError processing batch: ~p~n" (list reason))
      (tuple 'error reason)))))

(defun wait-for-resume ()
  "Wait for user to call resume"
  ;; This is a blocking wait - in practice the user calls resume from REPL
  (timer:sleep 1000)
  (case (sbf_state:get_status)
    ((map 'state 'waiting_confirmation)
     (wait-for-resume))
    (_ 'ok)))

(defun partition-list (list size)
  "Partition list into chunks of size"
  (partition-list list size '()))

(defun partition-list
  (('() _ acc)
   (lists:reverse acc))
  ((list size acc)
   (let ((chunk (lists:sublist list size))
         (rest (lists:nthtail (min size (length list)) list)))
     (partition-list rest size (cons chunk acc)))))

(defun get-batch-size ()
  "Get batch size (same as pause interval for now)"
  (get-pause-interval))

(defun get-pause-interval ()
  "Get pause interval from config"
  (case (application:get_env 'safe_brute_force 'pause_interval)
    ((tuple 'ok value) value)
    ('undefined 25)))

(defun min (a b)
  (if (< a b) a b))
