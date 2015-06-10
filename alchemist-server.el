;;; alchemist-server.el ---

;; Copyright © 2015 Samuel Tonini

;; Author: Samuel Tonini <tonini.samuel@gmail.com

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:


(require 'f)

(defvar alchemist-server
  (f-join (f-dirname load-file-name) "alchemist.exs")
  "Script file with alchemist server.")

(defvar alchemist-server-processes '())
(defvar alchemist-server-env "dev")

(defvar alchemist-server-command
  (format "elixir %s %s" alchemist-server alchemist-server-env))

(defun alchemist-server-start ()
  (let* ((process-name (alchemist-server-process-name))
         (default-directory (if (string= process-name "alchemist-server")
                                default-directory
                              process-name))
         (process (start-process-shell-command process-name "*alchemist-server*" alchemist-server-command)))
    (add-to-list 'alchemist-server-processes (cons process-name process))))

(defun alchemist-server-process-name ()
  (let* ((process-name (alchemist-project-root))
         (process-name (if process-name
                           process-name
                         "alchemist-server")))
    process-name))

(defun alchemist-server-process-p ()
  (process-live-p (alchemist-server-process)))

(defun alchemist-server-process ()
  (cdr (assoc (alchemist-server-process-name) alchemist-server-processes)))

(defun alchemist-server-doc-filter (process output)
  (setq alchemist-server--output (cons output alchemist-server--output))
  (if (string-match "END-OF-DOC$" output)
      (alchemist-help--initialize-buffer (apply #'concat (reverse alchemist-server--output)))))

(defun alchemist-server-complete-canidates-filter (process output)
  (setq alchemist-server--output (cons output alchemist-server--output))
  (if (string-match "END-OF-COMPLETE$" output)
      (let* ((string (apply #'concat (reverse alchemist-server--output)))
            (string (replace-regexp-in-string "END-OF-COMPLETE$" "" string))
            (candidates (alchemist-complete--output-to-list
                         (alchemist--utils-clear-ansi-sequences string)))
            (candidates (alchemist-complete--build-candidates candidates)))
        (funcall alchemist-server-company-callback candidates))))

(defun alchemist-server-complete-candidates (exp)
  (setq alchemist-server--output nil)
  (unless (alchemist-server-process-p)
    (alchemist-server-start))
  (set-process-filter (alchemist-server-process) #'alchemist-server-complete-canidates-filter)
  (process-send-string (alchemist-server-process) (format "COMPLETE %s\n" exp)))

;; (rplacd (assoc 'y values) 201)

(provide 'alchemist-server)

;;; alchemist-server.el ends here
