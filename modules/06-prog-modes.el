;; -*- emacs-lisp -*-

;;; GENERAL

;; four space tab stops in general, using spaces
(setq-default tab-width 4)
(setq c-basic-offset 4)
(setq-default indent-tabs-mode nil)

;; auto-complete-mode, completion and popup help
(require 'auto-complete)
(require 'auto-complete-config)
(ac-config-default)
(global-auto-complete-mode t)
(setq ac-use-quick-help t
      ac-auto-show-menu 0.0
      ac-quick-help-delay 0.3)
(ac-flyspell-workaround)
(define-key ac-complete-mode-map [tab] 'ac-expand)
(define-key ac-mode-map (kbd "M-TAB") 'auto-complete)
(diminish 'auto-complete-mode)

;; hook AC into completion-at-point
(defun set-auto-complete-as-completion-at-point-function ()
  (setq completion-at-point-functions '(auto-complete)))
(add-hook 'auto-complete-mode-hook 'set-auto-complete-as-completion-at-point-function)

;; Various superfluous white-space: kill it
(defun cleanup-buffer-safe ()
  "Perform a bunch of safe operations on the whitespace content of a buffer.
Does not indent buffer, because it is used for a before-save-hook, and that
might be bad."
  (interactive)
  (untabify (point-min) (point-max))
  (delete-trailing-whitespace)
  (set-buffer-file-coding-system 'utf-8))

(defun cleanup-buffer ()
  "Perform a bunch of operations on the whitespace content of a buffer.
Including indent-buffer, which should not be called automatically on save."
  (interactive)
  (cleanup-buffer-safe)
  (indent-region (point-min) (point-max)))

;; prog-mode-hook to hightlight XXX, BUG and TODO in code
(add-hook 'prog-mode-hook
          (lambda ()
            (font-lock-add-keywords
             nil '(("\\<\\(XXX\\|BUG\\|TODO\\)" 1 font-lock-warning-face prepend)))))

;;;;;; LISPS

;; highlight matching parens, please
(show-paren-mode)

(define-key read-expression-map (kbd "TAB") 'lisp-complete-symbol)
(define-key lisp-mode-shared-map (kbd "RET") 'reindent-then-newline-and-indent)

;; paredit all the parens
(dolist (mode '(scheme emacs-lisp lisp clojure clojurescript))
    (add-hook (intern (concat (symbol-name mode) "-mode-hook"))
              'paredit-mode))

;; keybinding stolen from Lighttable
(global-set-key (kbd "<s-return>") 'eval-defun)
(define-key emacs-lisp-mode-map (kbd "<s-return>") 'eval-defun)
(eval-after-load 'clojure-mode
  '(define-key clojure-mode-map (kbd "<s-return>") 'nrepl-eval-expression-at-point))

;;; PAREDIT

;; adjust paredit's key bindings so they don't override my preferred
;; navigation keys, add brace matching goodies across all modes
(eval-after-load 'paredit
  '(progn
     ;; fights with my preferred navigation keys
     (dolist (binding (list (kbd "M-<up>") (kbd "M-<down>") (kbd "C-M-<left>") (kbd "C-M-<right>")))
       (define-key paredit-mode-map binding nil))

     ;; not just in lisp mode(s) 
     (global-set-key (kbd "C-M-<left>") 'backward-sexp)
     (global-set-key (kbd "C-M-<right>") 'forward-sexp)

     (global-set-key (kbd "M-(") 'paredit-wrap-round)
     (global-set-key (kbd "M-[") 'paredit-wrap-square)
     (global-set-key (kbd "M-{") 'paredit-wrap-curly)

     (global-set-key (kbd "M-)") 'paredit-close-round-and-newline)
     (global-set-key (kbd "M-]") 'paredit-close-square-and-newline)
     (global-set-key (kbd "M-}") 'paredit-close-curly-and-newline)

	 (diminish 'paredit-mode)))

;; Enable `paredit-mode' in the minibuffer, during `eval-expression'.
(defun conditionally-enable-paredit-mode ()
  (if (eq this-command 'eval-expression)
      (paredit-mode 1)))

(add-hook 'minibuffer-setup-hook 'conditionally-enable-paredit-mode)

;; making paredit work with delete-selection-mode
(put 'paredit-forward-delete 'delete-selection 'supersede)
(put 'paredit-backward-delete 'delete-selection 'supersede)
(put 'paredit-newline 'delete-selection t)

;;; ELISP

(add-hook 'emacs-lisp-mode-hook 'elisp-slime-nav-mode)
(add-hook 'emacs-lisp-mode-hook 'turn-on-eldoc-mode)

(eval-after-load 'eldoc
  '(diminish 'eldoc-mode))

(defun elisp-popup-doc ()
  "Use auto-complete's popup support to look up docs in emacs-lisp buffers."
  (interactive)
  (popup-tip (ac-symbol-documentation (symbol-at-point))
             :around t
             :scroll-bar t
             :margin t))

(define-key lisp-interaction-mode-map (kbd "C-c C-d") 'elisp-popup-doc)
(define-key emacs-lisp-mode-map (kbd "C-c C-r") 'eval-region)

;; BUG currently shadowed?
(define-key emacs-lisp-mode-map (kbd "C-c C-d") 'elisp-popup-doc)

;; TODO binding?
(defun eval-and-replace ()
  "Replace the preceding sexp with its value."
  (interactive)
  (backward-kill-sexp)
  (condition-case nil
      (prin1 (eval (read (current-kill 0)))
             (current-buffer))
    (error (message "Invalid expression")
           (insert (current-kill 0)))))

;;; SCHEME

;;;; use geiser for racket (also good for guile)
(setq geiser-active-implementations '(racket))

;;; COMMON LISP

;; Clozure CL or sbcl with quicklisp under slime
(setq slime-lisp-implementations
           '((ccl64 ("/usr/local/bin/ccl64" "-K utf-8") :coding-system utf-8-unix)
             (sbcl ("/usr/local/bin/sbcl --noinform") :coding-system utf-8-unix)))

;; install the quicklisp helper
(let ((ql-slime-help (expand-file-name "~/quicklisp/slime-helper.el")))
  (when (file-exists-p ql-slime-help) (load ql-slime-help)))

;; add auto-completion for slime
(slime-setup '(slime-fancy))
(add-hook 'slime-mode-hook 'set-up-slime-ac)
(add-hook 'slime-repl-mode-hook 'set-up-slime-ac)
(eval-after-load "auto-complete"
   '(add-to-list 'ac-modes 'slime-repl-mode))

;;; CLOJURE

;; ac-mode for clojure and the nREPL
(eval-after-load "auto-complete"
  '(progn
    (add-to-list 'ac-modes 'clojure-mode)
	(add-to-list 'ac-modes 'nrepl-mode)))

(require 'ac-nrepl)
(add-hook 'nrepl-mode-hook 'ac-nrepl-setup)
(add-hook 'nrepl-interaction-mode-hook 'ac-nrepl-setup)

(add-hook 'nrepl-mode-hook 'set-auto-complete-as-completion-at-point-function)
(add-hook 'nrepl-interaction-mode-hook 'set-auto-complete-as-completion-at-point-function)
(add-hook 'nrepl-interaction-mode-hook 'nrepl-turn-on-eldoc-mode)
(define-key nrepl-interaction-mode-map (kbd "C-c C-d") 'ac-nrepl-popup-doc)

;; add ritz to nrepl under clojure XXX
;; (add-hook 'nrepl-interaction-mode-hook 'my-nrepl-mode-setup)
;; (defun my-nrepl-mode-setup ()
;;   (require 'nrepl-ritz))

;; this is needed to prevent ac-nrepl from breaking
;; nrepl-jack-in
(setq nrepl-connected-hook (reverse nrepl-connected-hook))

;; no need, no need!
(setq nrepl-popup-stacktraces nil)

;; highlight evaluated sexp to give visual cue of action and scope
(require 'nrepl-eval-sexp-fu)

;;;;;; HASKELL 

;;;; Haskell
(add-hook 'haskell-mode-hook 'turn-on-haskell-doc-mode)
(add-hook 'haskell-mode-hook 'turn-on-haskell-indentation)

;; Ignore compiled Haskell files in filename completions
(add-to-list 'completion-ignored-extensions ".hi")

;;;;;; RUBY/RUBYMOTION

;; ruby, using robe
(define-key ruby-mode-map (kbd "RET") 'reindent-then-newline-and-indent)
(add-hook 'ruby-mode-hook 'flymake-ruby-load)
(add-hook 'ruby-mode-hook 'robe-mode)
(add-hook 'robe-mode-hook
          (lambda ()
            (add-to-list 'ac-sources 'ac-source-robe)
            (setq completion-at-point-functions '(auto-complete))))

;; some ruby motion stuff
(require 'motion-mode)
(add-hook 'ruby-mode-hook 'motion-recognize-project)
(add-to-list 'ac-modes 'motion-mode)
(add-to-list 'ac-sources 'ac-source-dictionary)

(define-key motion-mode-map (kbd "C-c C-c") 'motion-execute-rake)
(define-key motion-mode-map (kbd "C-c C-d") 'motion-dash-at-point)
(define-key motion-mode-map (kbd "C-c C-p") 'motion-convert-code-region)

;;;;;; JAVASCRIPT/COFFEESCRIPT

;; js2-mode
(require 'js2-mode)
(setq-default js2-auto-indent-p t)
(setq-default js2-global-externs '("module" "require" "jQuery" "$" "_" "buster" "sinon" "assert" "refute" "setTimeout" "clearTimeout" "setInterval" "clearInterval" "location" "__dirname" "console" "JSON"))
(add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))

;; skewer mode for browser mind control
(require 'skewer-mode)
(require 'skewer-repl)
(require 'skewer-html)
(require 'skewer-css)
(defun skewer-start ()
  (interactive)
  (let ((httpd-port 8023))
    (httpd-start)
    (message "Ready to skewer the browser. Now jack in with the bookmarklet.")))

;; Bookmarklet to connect to skewer from the browser:
;; javascript:(function(){var d=document ;var s=d.createElement('script');s.src='http://localhost:8023/skewer';d.body.appendChild(s);})()

;;two space tabs in coffee
(defun coffee-custom ()
  "coffee-mode-hook"
  (set (make-local-variable 'tab-width) 2))
(add-hook 'coffee-mode-hook '(lambda() (coffee-custom)))

;;;;;; CSS

;; indent for me, emacs
(eval-after-load 'css-mode
  '(define-key css-mode-map (kbd "RET") 'reindent-then-newline-and-indent))