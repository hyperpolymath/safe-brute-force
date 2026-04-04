;;;; SafeBruteForce Checkpoint System
;;;; Save and restore brute-force session state

(defmodule sbf_checkpoint
  (export
   (save 2)
   (save 3)
   (restore 1)
   (list_checkpoints 0)
   (list_checkpoints 1)
   (delete 1)
   (auto_save 1)))

;;; ============================================================
;;; Checkpoint API
;;; ============================================================

(defun save (session-name state)
  "Save current session state with auto-generated ID"
  (let ((checkpoint-id (generate-checkpoint-id session-name)))
    (save session-name checkpoint-id state)))

(defun save (session-name checkpoint-id state)
  "Save session state with specific checkpoint ID"
  (let* ((checkpoint-dir (get-checkpoint-dir))
         (filename (checkpoint-filename session-name checkpoint-id))
         (filepath (filename:join checkpoint-dir filename))
         (checkpoint-data (create-checkpoint-data state)))
    ;; Ensure directory exists
    (filelib:ensure_dir filepath)
    ;; Save checkpoint
    (case (file:write_file filepath (term_to_binary checkpoint-data))
      ('ok
       (tuple 'ok (map 'session session-name
                       'checkpoint_id checkpoint-id
                       'filename filepath
                       'timestamp (maps:get 'timestamp checkpoint-data))))
      ((tuple 'error reason)
       (tuple 'error (map 'session session-name
                          'checkpoint_id checkpoint-id
                          'reason reason))))))

(defun restore (checkpoint-id)
  "Restore session state from checkpoint"
  (case (find-checkpoint-file checkpoint-id)
    ((tuple 'ok filepath)
     (case (file:read_file filepath)
       ((tuple 'ok binary-data)
        (try
          (let ((checkpoint-data (binary_to_term binary-data)))
            (tuple 'ok checkpoint-data))
          (catch
            ((tuple type error)
             (tuple 'error (tuple 'invalid_checkpoint type error))))))
       ((tuple 'error reason)
        (tuple 'error reason))))
    ((tuple 'error reason)
     (tuple 'error reason))))

(defun list_checkpoints ()
  "List all checkpoints"
  (list_checkpoints 'all))

(defun list_checkpoints (session-name)
  "List checkpoints for specific session or all sessions"
  (let* ((checkpoint-dir (get-checkpoint-dir))
         (pattern (case session-name
                   ('all "*.checkpoint")
                   (_ (++ (atom_to_list session-name) "_*.checkpoint"))))
         (files (filelib:wildcard pattern checkpoint-dir)))
    (lists:map
     (lambda (filename)
       (parse-checkpoint-filename filename))
     files)))

(defun delete (checkpoint-id)
  "Delete a checkpoint"
  (case (find-checkpoint-file checkpoint-id)
    ((tuple 'ok filepath)
     (case (file:delete filepath)
       ('ok (tuple 'ok (map 'checkpoint_id checkpoint-id
                            'deleted 'true)))
       ((tuple 'error reason)
        (tuple 'error reason))))
    ((tuple 'error reason)
     (tuple 'error reason))))

(defun auto_save (state)
  "Auto-save with timestamp-based ID
   Returns updated state with checkpoint_id"
  (let* ((session-name 'default)
         (checkpoint-id (generate-checkpoint-id session-name))
         (result (save session-name checkpoint-id state)))
    (case result
      ((tuple 'ok info)
       (io:format "[Checkpoint] Auto-saved: ~s~n" (list checkpoint-id))
       (tuple 'ok (maps:put 'checkpoint_id checkpoint-id state)))
      ((tuple 'error reason)
       (io:format "[Checkpoint] Auto-save failed: ~p~n" (list reason))
       (tuple 'error reason)))))

;;; ============================================================
;;; Internal Functions
;;; ============================================================

(defun create-checkpoint-data (state)
  "Create checkpoint data structure from state"
  (map 'version "0.1.0"
       'timestamp (erlang:system_time 'second)
       'state state
       'metadata (map 'created_by "sbf_checkpoint"
                      'erlang_version (erlang:system_info 'otp_release))))

(defun generate-checkpoint-id (session-name)
  "Generate unique checkpoint ID"
  (let* ((timestamp (erlang:system_time 'millisecond))
         (random (rand:uniform 9999)))
    (lists:flatten
     (io_lib:format "~s_~B_~4..0B"
                    (list session-name timestamp random)))))

(defun checkpoint-filename (session-name checkpoint-id)
  "Generate checkpoint filename"
  (++ checkpoint-id ".checkpoint"))

(defun get-checkpoint-dir ()
  "Get checkpoint directory from application config"
  (case (application:get_env 'safe_brute_force 'checkpoint_dir)
    ((tuple 'ok dir) dir)
    ('undefined "priv/checkpoints")))

(defun find-checkpoint-file (checkpoint-id)
  "Find checkpoint file by ID"
  (let* ((checkpoint-dir (get-checkpoint-dir))
         (pattern (++ "*" checkpoint-id "*.checkpoint"))
         (files (filelib:wildcard pattern checkpoint-dir)))
    (case files
      ('() (tuple 'error 'checkpoint_not_found))
      ((cons file _)
       (tuple 'ok (filename:join checkpoint-dir file))))))

(defun parse-checkpoint-filename (filename)
  "Parse checkpoint filename to extract metadata"
  (let* ((base (filename:basename filename ".checkpoint"))
         (parts (string:split base "_" 'all)))
    (case parts
      ((list session timestamp id)
       (map 'session (list_to_atom session)
            'timestamp (list_to_integer timestamp)
            'id id
            'filename filename))
      (_ (map 'filename filename
              'parse_error 'true)))))

;;; ============================================================
;;; Checkpoint Management
;;; ============================================================

(defun cleanup_old_checkpoints (max-age-seconds)
  "Delete checkpoints older than max-age-seconds"
  (let* ((current-time (erlang:system_time 'second))
         (cutoff-time (- current-time max-age-seconds))
         (all-checkpoints (list_checkpoints)))
    (lists:foreach
     (lambda (checkpoint)
       (let ((timestamp (maps:get 'timestamp checkpoint)))
         (when (< timestamp cutoff-time)
           (delete (maps:get 'id checkpoint)))))
     all-checkpoints)))

(defun get_checkpoint_info (checkpoint-id)
  "Get detailed information about a checkpoint without loading full state"
  (case (find-checkpoint-file checkpoint-id)
    ((tuple 'ok filepath)
     (case (file:read_file filepath)
       ((tuple 'ok binary-data)
        (try
          (let* ((checkpoint-data (binary_to_term binary-data))
                 (metadata (maps:get 'metadata checkpoint-data))
                 (timestamp (maps:get 'timestamp checkpoint-data))
                 (version (maps:get 'version checkpoint-data))
                 (state (maps:get 'state checkpoint-data))
                 (attempts (maps:get 'attempt_count state 0))
                 (successes (maps:get 'success_count state 0)))
            (tuple 'ok (map 'checkpoint_id checkpoint-id
                            'timestamp timestamp
                            'version version
                            'metadata metadata
                            'attempts attempts
                            'successes successes
                            'filepath filepath)))
          (catch
            ((tuple type error)
             (tuple 'error (tuple 'invalid_checkpoint type error))))))
       ((tuple 'error reason)
        (tuple 'error reason))))
    ((tuple 'error reason)
     (tuple 'error reason))))
