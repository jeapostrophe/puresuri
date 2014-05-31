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
             ;; xxx slide names
             [(or #\space 'right)
              (set! current-slide (add1 current-slide))
              (refresh!)]
             [(or 'left)
              (set! current-slide (max 0 (sub1 current-slide)))
              (refresh!)]
             [\#r
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
    (define base 
      (colorize (filled-rectangle slide-w slide-h) "white"))
    (define almost-pict
      (ST-cmds-interp the-ST current-slide base))
    (define nearly-pict
      (ST-pipeline-apply the-ST almost-pict))
    (define final-pict
      (scale-to-fit (clip nearly-pict) aw ah))
    (draw-pict-centered final-pict the-dc aw ah))

  (define pf (new pres-frame% [label "Puresuri"]))
  (define pc (new canvas% [parent pf]
                  [paint-callback paint-canvas]))
  (define (refresh!)
    (send pc refresh))
  (define the-dc (send pc get-dc))
  (dc-for-text-size the-dc)

  (define (error-display x)
    ((error-display-handler)
     (if (exn? x)
       (exn-message x)
       "non-exn error:")
     x))

  (define (load-mp!)
    (define new-ST (make-fresh-ST))
    (with-handlers ([(λ (x)
                       (not (exn:break? x)))
                     (λ (x)
                       ;; xxx put error message on screen
                       (error-display x))])
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

(module+ main
  (require racket/runtime-path
           racket/cmdline)

  (define-runtime-path ex "tests/example.rkt")
  (current-command-line-arguments
   (vector (path->string ex)))

  ;; xxx printing

  (command-line
   #:program "puresuri"
   #:args (module-path)
   (puresuri! module-path)))
