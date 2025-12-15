;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
;; ECOSYSTEM.scm — safe-brute-force

(ecosystem
  (version "1.0.0")
  (name "safe-brute-force")
  (type "project")
  (purpose "A *controlled, ethical brute-force utility* designed for authorized security testing and penetration testing engagements. Unlike traditional brute-force tools that flood systems recklessly, SafeBruteF...")

  (position-in-ecosystem
    "Part of hyperpolymath ecosystem. Follows RSR guidelines.")

  (related-projects
    (project (name "rhodium-standard-repositories")
             (url "https://github.com/hyperpolymath/rhodium-standard-repositories")
             (relationship "standard")))

  (what-this-is "A *controlled, ethical brute-force utility* designed for authorized security testing and penetration testing engagements. Unlike traditional brute-force tools that flood systems recklessly, SafeBruteF...")
  (what-this-is-not "- NOT exempt from RSR compliance"))
