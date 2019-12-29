;;; Code:

(require 'package)
(setq package-enable-at-startup nil)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/"))
(unless package--initialized (package-initialize))

(require 'org)
(org-babel-load-file (expand-file-name "~/.emacs.d/emacs-init.org"))

;;; init.el ends here
