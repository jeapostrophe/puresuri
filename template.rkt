#lang racket/base
(require slideshow
         racket/gui/base
         unstable/gui/pslide
         unstable/gui/ppict
         ppict-slide-grid
         "title.rkt")
(module+ test)

;; xxx add keyboard short-cuts to slideshow that bangs DEPLOY?

(define DEPLOY? #f)

(set-page-numbers-visible! #f)
(set-margin! 0)

(define default-sa (current-slide-assembler))
(define grid-background (grid-base-pict))
(define (gride-sa t x p)
  (define orig
    (default-sa t x p))
  (if DEPLOY?
    orig
    (cc-superimpose
     orig
     grid-background)))
(current-slide-assembler gride-sa)

(define my-bg (make-plt-title-background* client-w client-h))

;; xxx pslide's default is #:add
;; xxx add #:label label-e pict-e
;; xxx add #:del label-e
;; xxx add functions/abstractions/loops
;; xxx typo in ppict-do* do
;; xxx internal defines in pslide
;; xxx add #:save and #:restore
;; xxx slideshow - add rerequire mode that goes to Ith slide or named slide
;; xxx figure out how to scale slideshow properly in xmonad
;; xxx pslide with functions rather than syntax

(module+ main
  (pslide
   #:go (coord 1/2 1/2 'cc)
   my-bg
   #:next
   #:go (coord 2/3 2/3 'cc)
   (scale my-bg 1/2)
   #:next
   #:go (coord 1/3 1/3 'cc)
   (scale my-bg 1/2)))
