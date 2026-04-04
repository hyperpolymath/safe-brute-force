;;;; SafeBruteForce Supervisor
;;;; Top-level supervisor for the application

(defmodule sbf_sup
  (behaviour supervisor)
  (export
   (start_link 1)
   (init 1)))

(defun start_link (config)
  "Start the supervisor"
  (supervisor:start_link
   (tuple 'local 'sbf_sup)
   'sbf_sup
   config))

(defun init (config)
  "Initialize the supervisor with child specifications"
  (let ((children
         (list
          ;; State Manager (gen_statem)
          (map 'id 'sbf_state_manager
               'start (tuple 'sbf_state 'start_link (list config))
               'restart 'permanent
               'shutdown 5000
               'type 'worker
               'modules (list 'sbf_state))

          ;; Executor (gen_server)
          (map 'id 'sbf_executor
               'start (tuple 'sbf_executor 'start_link (list config))
               'restart 'permanent
               'shutdown 5000
               'type 'worker
               'modules (list 'sbf_executor)))))

    (tuple 'ok
           (tuple (map 'strategy 'one_for_one
                       'intensity 10
                       'period 60)
                  children))))
