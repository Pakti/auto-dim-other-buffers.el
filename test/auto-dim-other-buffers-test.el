;;; auto-dim-other-buffers-test.el --- Minibuffer checks -*- lexical-binding: t -*-
(require 'ert)
(require 'cl-lib)
(require 'auto-dim-other-buffers)

(ert-deftest adob-test-inactive-minibuffer ()
  (let ((auto-dim-other-buffers-dim-inactive-minibuffer nil)
        (mini (minibuffer-window)))
    (unwind-protect
        (progn
          (auto-dim-other-buffers-mode 1)
          (should-not (window-parameter mini 'adob--dim))
          (setq auto-dim-other-buffers-dim-inactive-minibuffer t)
          (adob--update)
          (should (window-parameter mini 'adob--dim))
          (should (buffer-local-value 'adob--face-mode-remapping
                                      (window-buffer mini)))
          (adob--rescan-windows)
          (should (window-parameter mini 'adob--dim))
          ;; An active minibuffer stays lit with either setting for the
          ;; previously selected ordinary window.
          (dolist (switch '(nil t))
            (let ((auto-dim-other-buffers-dim-on-switch-to-minibuffer switch))
              (cl-letf (((symbol-function 'active-minibuffer-window)
                         (lambda () mini)))
                (adob--update)
                (should-not (window-parameter mini 'adob--dim))
                ;; Exiting a recursive minibuffer leaves its parent active.
                (cl-letf (((symbol-function 'minibuffer-depth) (lambda () 2)))
                  (adob--minibuffer-exit)
                  (should-not (window-parameter mini 'adob--dim)))
                (cl-letf (((symbol-function 'minibuffer-depth) (lambda () 1)))
                  (adob--minibuffer-exit)
                  (should (window-parameter mini 'adob--dim))))))
          ;; Customize changes are applied while the mode is running.
          (customize-set-variable
           'auto-dim-other-buffers-dim-inactive-minibuffer nil)
          (should-not (window-parameter mini 'adob--dim))
          (customize-set-variable
           'auto-dim-other-buffers-dim-inactive-minibuffer t)
          (should (window-parameter mini 'adob--dim))
          (auto-dim-other-buffers-mode -1)
          (should-not (window-parameter mini 'adob--dim))
          (should-not (buffer-local-value 'adob--face-mode-remapping
                                          (window-buffer mini))))
      (auto-dim-other-buffers-mode -1)
      (customize-set-variable
       'auto-dim-other-buffers-dim-inactive-minibuffer nil))))
