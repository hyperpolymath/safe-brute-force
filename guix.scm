;; safe-brute-force - Guix Package Definition
;; Run: guix shell -D -f guix.scm

(use-modules (guix packages)
             (guix gexp)
             (guix git-download)
             (guix build-system gnu)
             ((guix licenses) #:prefix license:)
             (gnu packages base))

(define-public safe_brute_force
  (package
    (name "safe-brute-force")
    (version "0.1.0")
    (source (local-file "." "safe-brute-force-checkout"
                        #:recursive? #t
                        #:select? (git-predicate ".")))
    (build-system gnu-build-system)
    (synopsis "Controlled, ethical brute-force utility for authorized security testing")
    (description "SafeBruteForce is a controlled, ethical brute-force utility designed for authorized security testing. Features mandatory safety pauses every 25 attempts, rate limiting, checkpointing, and clean output filtering. Built with LFE on Erlang/OTP.")
    (home-page "https://github.com/hyperpolymath/safe-brute-force")
    (license license:agpl3+)))

;; Return package for guix shell
safe_brute_force
