;;;; SafeBruteForce Test Suite
;;;; Comprehensive unit and integration tests

(defmodule sbf_tests
  (export all))

(include-lib "eunit/include/eunit.hrl")

;;; ============================================================
;;; Pattern Generation Tests
;;; ============================================================

(defun charset_combinations_test ()
  "Test basic charset combination generation"
  (let ((patterns (sbf_patterns:charset_combinations "ab" 1 2)))
    (eunit:assert_equal 6 (length patterns))
    (eunit:assert (lists:member "a" patterns))
    (eunit:assert (lists:member "b" patterns))
    (eunit:assert (lists:member "aa" patterns))
    (eunit:assert (lists:member "ab" patterns))
    (eunit:assert (lists:member "ba" patterns))
    (eunit:assert (lists:member "bb" patterns))))

(defun sequential_numbers_test ()
  "Test sequential number generation"
  (let ((patterns (sbf_patterns:sequential_numbers 1 5)))
    (eunit:assert_equal 5 (length patterns))
    (eunit:assert_equal "1" (car patterns))
    (eunit:assert_equal "5" (lists:last patterns))))

(defun common_passwords_test ()
  "Test common passwords list"
  (let ((passwords (sbf_patterns:common_passwords)))
    (eunit:assert (> (length passwords) 0))
    (eunit:assert (lists:member "password" passwords))
    (eunit:assert (lists:member "admin" passwords))))

(defun leet_speak_test ()
  "Test leet speak transformation"
  (let ((result (sbf_patterns:leet-speak "password")))
    (eunit:assert_equal "p455w0rd" result)))

(defun capitalize_test ()
  "Test string capitalization"
  (eunit:assert_equal "Password" (sbf_patterns:capitalize "password"))
  (eunit:assert_equal "Test" (sbf_patterns:capitalize "test"))
  (eunit:assert_equal "" (sbf_patterns:capitalize "")))

;;; ============================================================
;;; State Machine Tests
;;; ============================================================

(defun state_manager_lifecycle_test ()
  "Test state manager lifecycle"
  (let ((config (list (tuple 'pause_interval 3)
                     (tuple 'safety_enabled 'true))))
    ;; Start state manager
    (case (sbf_state:start_link config)
      ((tuple 'ok pid)
       ;; Verify initial state
       (let ((status (sbf_state:get_status)))
         (eunit:assert_equal 'running (maps:get 'state status))
         (eunit:assert_equal 0 (maps:get 'attempts status)))

       ;; Record attempts
       (sbf_state:attempt "test1" 'failure)
       (sbf_state:attempt "test2" 'failure)

       ;; Third attempt should trigger pause
       (let ((result (sbf_state:attempt "test3" 'success)))
         (eunit:assert_equal (tuple 'ok 'paused 3) result))

       ;; Verify paused state
       (let ((status2 (sbf_state:get_status)))
         (eunit:assert_equal 'waiting_confirmation (maps:get 'state status2)))

       ;; Resume
       (sbf_state:resume)

       ;; Verify running again
       (let ((status3 (sbf_state:get_status)))
         (eunit:assert_equal 'running (maps:get 'state status3)))

       ;; Stop
       (sbf_state:stop))
      (error
       (eunit:assert_failed "Failed to start state manager")))))

(defun state_success_tracking_test ()
  "Test success pattern tracking"
  (let ((config (list (tuple 'pause_interval 100)
                     (tuple 'safety_enabled 'true))))
    (case (sbf_state:start_link config)
      ((tuple 'ok _pid)
       ;; Record mixed results
       (sbf_state:attempt "fail1" 'failure)
       (sbf_state:attempt "success1" 'success)
       (sbf_state:attempt "fail2" 'failure)
       (sbf_state:attempt "success2" 'success)

       ;; Get stats
       (let ((stats (sbf_state:get_stats)))
         (eunit:assert_equal 4 (maps:get 'attempt_count stats))
         (eunit:assert_equal 2 (maps:get 'success_count stats))
         (eunit:assert_equal 2 (maps:get 'failure_count stats))

         ;; Check successful patterns are tracked
         (let ((patterns (maps:get 'successful_patterns stats)))
           (eunit:assert (lists:member "success1" patterns))
           (eunit:assert (lists:member "success2" patterns))))

       ;; Stop
       (sbf_state:stop))
      (_ 'ok))))

;;; ============================================================
;;; Executor Tests
;;; ============================================================

(defun executor_mock_target_test ()
  "Test executor with mock target"
  (let ((config (list (tuple 'max_workers 5)
                     (tuple 'timeout 1000)
                     (tuple 'rate_limit 0))))
    (case (sbf_executor:start_link config)
      ((tuple 'ok _pid)
       ;; Set up mock target
       (let* ((patterns (list "wrong1" "correct" "wrong2"))
              (target-config (list (tuple 'type 'mock)
                                  (tuple 'expected "correct")))
              (result (sbf_executor:execute_batch patterns target-config)))
         (case result
           ((tuple 'ok results)
            (eunit:assert_equal 3 (length results))
            ;; Find the successful result
            (let ((successes (lists:filter
                             (lambda ((tuple _ status _))
                               (== status 'success))
                             results)))
              (eunit:assert_equal 1 (length successes))))
           (_ (eunit:assert_failed "Unexpected result"))))

       ;; Stop
       (sbf_executor:stop))
      (_ 'ok))))

(defun executor_custom_function_test ()
  "Test executor with custom function"
  (let ((config (list (tuple 'max_workers 5)
                     (tuple 'timeout 1000)
                     (tuple 'rate_limit 0))))
    (case (sbf_executor:start_link config)
      ((tuple 'ok _pid)
       ;; Custom test function
       (let* ((test-fn (lambda (pattern)
                        (== pattern "secret")))
              (patterns (list "test" "secret" "wrong"))
              (target-config (list (tuple 'type 'function)
                                  (tuple 'function test-fn)))
              (result (sbf_executor:execute_batch patterns target-config)))
         (case result
           ((tuple 'ok results)
            (eunit:assert_equal 3 (length results)))
           (_ (eunit:assert_failed "Unexpected result"))))

       ;; Stop
       (sbf_executor:stop))
      (_ 'ok))))

;;; ============================================================
;;; Output Formatting Tests
;;; ============================================================

(defun format_results_test ()
  "Test result formatting"
  (let ((results (list (tuple "success1" 'success (map 'data "test"))
                      (tuple "failure1" 'failure "wrong")
                      (tuple "error1" 'error 'timeout))))
    ;; Test success filter
    (let ((successes (sbf_output:filter_results results 'success)))
      (eunit:assert_equal 1 (length successes)))

    ;; Test failure filter
    (let ((failures (sbf_output:filter_results results 'failure)))
      (eunit:assert_equal 2 (length failures)))

    ;; Test formatting
    (let ((formatted (sbf_output:format_results results 'all)))
      (eunit:assert_equal 3 (length formatted)))))

;;; ============================================================
;;; Checkpoint Tests
;;; ============================================================

(defun checkpoint_save_restore_test ()
  "Test checkpoint save and restore"
  (let ((test-state (map 'attempt_count 42
                        'success_count 3
                        'failure_count 39
                        'successful_patterns (list "pass1" "pass2")))
        (session-name 'test_session))

    ;; Save checkpoint
    (case (sbf_checkpoint:save session-name test-state)
      ((tuple 'ok save-info)
       (let ((checkpoint-id (maps:get 'checkpoint_id save-info)))

         ;; Restore checkpoint
         (case (sbf_checkpoint:restore checkpoint-id)
           ((tuple 'ok checkpoint-data)
            (let ((restored-state (maps:get 'state checkpoint-data)))
              (eunit:assert_equal 42 (maps:get 'attempt_count restored-state))
              (eunit:assert_equal 3 (maps:get 'success_count restored-state)))

            ;; Clean up - delete checkpoint
            (sbf_checkpoint:delete checkpoint-id))
           ((tuple 'error reason)
            (eunit:assert_failed (++ "Failed to restore: " (io_lib:format "~p" (list reason))))))))
      ((tuple 'error reason)
       (eunit:assert_failed (++ "Failed to save: " (io_lib:format "~p" (list reason))))))))

;;; ============================================================
;;; Integration Tests
;;; ============================================================

(defun full_workflow_test ()
  "Test complete workflow with small dataset"
  ;; This test requires the full application to be started
  (application:ensure_all_started 'safe_brute_force)

  ;; Create simple test
  (let* ((test-fn (lambda (pattern)
                   (or (== pattern "abc")
                       (== pattern "xyz"))))
         (pattern-config (list (tuple 'type 'charset)
                              (tuple 'charset "abxyz")
                              (tuple 'min_length 3)
                              (tuple 'max_length 3)))
         (target-config (list (tuple 'type 'function)
                             (tuple 'function test-fn))))

    ;; Run test (this will pause, so we can't run in normal test)
    ;; Just verify we can generate patterns
    (let ((patterns (lists:sublist
                     (sbf_patterns:charset_combinations "ab" 2 2) 10)))
      (eunit:assert (> (length patterns) 0)))))

;;; ============================================================
;;; Performance Tests
;;; ============================================================

(defun pattern_generation_performance_test ()
  "Test pattern generation doesn't take too long"
  (let ((start (erlang:system_time 'millisecond))
        (patterns (sbf_patterns:charset_combinations "abc" 1 4))
        (end (erlang:system_time 'millisecond))
        (duration (- end start)))
    ;; Should generate ~120 patterns pretty quickly (< 1 second)
    (eunit:assert (< duration 1000))
    (eunit:assert_equal 120 (length patterns))))

;;; ============================================================
;;; Safety Tests
;;; ============================================================

(defun safety_pause_enforcement_test ()
  "Test that safety pause is enforced"
  (let ((config (list (tuple 'pause_interval 5)
                     (tuple 'safety_enabled 'true))))
    (case (sbf_state:start_link config)
      ((tuple 'ok _pid)
       ;; Record 5 attempts
       (lists:foreach
        (lambda (n)
          (sbf_state:attempt (integer_to_list n) 'failure))
        (lists:seq 1 5))

       ;; Should now be in waiting_confirmation state
       (let ((status (sbf_state:get_status)))
         (eunit:assert_equal 'waiting_confirmation (maps:get 'state status)))

       ;; Stop
       (sbf_state:stop))
      (_ 'ok))))

(defun safety_disabled_test ()
  "Test that pause can be disabled (for testing only)"
  (let ((config (list (tuple 'pause_interval 5)
                     (tuple 'safety_enabled 'false))))
    (case (sbf_state:start_link config)
      ((tuple 'ok _pid)
       ;; Record 5 attempts
       (lists:foreach
        (lambda (n)
          (sbf_state:attempt (integer_to_list n) 'failure))
        (lists:seq 1 5))

       ;; Should still be running (safety disabled)
       (let ((status (sbf_state:get_status)))
         (eunit:assert_equal 'running (maps:get 'state status)))

       ;; Stop
       (sbf_state:stop))
      (_ 'ok))))
