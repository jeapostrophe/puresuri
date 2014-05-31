#lang racket/base
(require racket/class
         racket/list
         racket/contract/base
         racket/gui/base
         racket/match
         pict
         racket/rerequire
         puresuri
         puresuri/pict
         "private/param.rkt"
         "private/state.rkt")

;; xxx put in a library
(define (error-display x)
  ((error-display-handler)
   (if (exn? x)
     (exn-message x)
     "non-exn error:")
   x))

(define (puresuri! mp)
  (define the-ST (make-fresh-ST))

  (define pres-frame%
    (class frame%
      (define/override (on-size w h)
        (refresh!))
      (define/override (on-subwindow-char w e)
        (define k (send e get-key-code))
        (define h (ST-char-handler the-ST k))
        (cond
          [h
           (h)
           (refresh!)]
          [else
           (match k
             [(or #\q 'escape)
              (exit 0)]
             [(or #\space 'right)
              (set! current-slide (add1 current-slide))
              (refresh!)]
             [(or 'left)
              (set! current-slide (max 0 (sub1 current-slide)))
              (refresh!)]
             [#\r
              (refresh!)]
             [#\i
              (set! current-slide
                    (if (= current-slide +inf.0)
                      0
                      +inf.0))
              (refresh!)]
             [_
              #f])]))
      (super-new)))

  (define current-slide 0)
  (define (paint-canvas c dc)
    (send dc set-background "black")
    (send dc clear)

    (define-values (aw ah)
      (send c get-client-size))

    (define-values (actual-slide nearly-pict)
      (ST->slide-pict the-ST current-slide))

    (define final-pict
      (scale-to-fit nearly-pict aw ah))
    (draw-pict-centered final-pict the-dc aw ah))

  (define pf (new pres-frame% [label "Puresuri"]))
  (define pc (new canvas% [parent pf]
                  [paint-callback paint-canvas]))
  (define (refresh!)
    (send pc refresh))
  (define the-dc (send pc get-dc))
  (dc-for-text-size the-dc)

  (define (load-mp!)
    (define new-ST (make-fresh-ST))
    (with-handlers ([(λ (x)
                       (not (exn:break? x)))
                     error-display])
      (parameterize ([current-ST new-ST])
        (dynamic-rerequire `(file ,mp) #:verbosity 'reload))
      (set! the-ST new-ST))
    (refresh!))

  (load-mp!)

  (send pf show #t)

  (let loop ()
    (yield (filesystem-change-evt mp))
    (load-mp!)
    (loop)))

(define (ST->slide-pict st i)
  (define base
    (colorize (filled-rectangle slide-w slide-h) "white"))
  (define-values (actual-slide almost-pict)
    (ST-cmds-interp st i base))
  (define nearly-pict
    (clip
     (parameterize ([current-slide-number actual-slide])
       (ST-pipeline-apply st almost-pict))))
  (values actual-slide nearly-pict))

(define (ST->picts st)
  (let loop ([i 0])
    (define-values (ni p) (ST->slide-pict st i))
    (cons p (if (= i ni) empty (loop ni)))))

(define (puresuri->png-dir png-dir mp)
  (local-require racket/file
                 racket/format)
  (printf "Creating directory ~a\n" png-dir)
  (make-directory* png-dir)
  (define the-ST (make-fresh-ST))
  (printf "Loading slides...\n")
  (parameterize ([current-ST the-ST])
    (dynamic-require `(file ,mp) 0))
  (printf "Rendering slides...\n")
  (define ps (ST->picts the-ST))
  (define how-many (length ps))
  (define len (string-length (number->string how-many)))
  (for ([p (in-list ps)]
        [i (in-naturals)])
    (define ni
      (~a i #:min-width len #:align 'right #:pad-string "0"))
    (printf "Saving slide ~a...\n" ni)
    (define bm (pict->bitmap p))
    (send bm save-file
          (build-path png-dir (format "~a.png" ni))
          'png
          100)))

(module+ main
  (require racket/cmdline)

  ;; xxx printing

  (define operation puresuri!)

  (command-line
   #:program "puresuri"
   #:once-any
   [("--pngs") png-dir "Render as directory of pngs"
    (set! operation
          (λ (mp)
            (puresuri->png-dir png-dir mp)))]
   #:args (module-path)
   (operation module-path)))
