#lang racket/base
(require puresuri
         unstable/gui/pict/plt-logo)

(provide plt-title-background)

(define plt-title-background
  (make-plt-title-background slide-w slide-h))
