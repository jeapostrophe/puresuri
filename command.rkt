#lang racket/base
(require racket/class
         racket/list
         racket/contract/base
         racket/gui/base
         racket/match
         pict
         unstable/error
         unstable/gui/pict
         puresuri
         puresuri/pict
         "private/param.rkt"
         "private/state.rkt"
         lux
         lux/chaos/gui
         lux/chaos/gui/val)

;; xxx make this functional (remove set!s)
(define (puresuri! mp)
  (define the-ST (make-fresh-ST))
  (define run-effect? #f)
  (define current-slide 0)
  (define last-load 0)
  (define change? #t)
  (define last-pict #f)
  (define (load-mp!)
    (define cur (file-or-directory-modify-seconds mp))
    (when (< last-load cur)
      (with-handlers ([exn:not-break? error-display])
        (set! the-ST (load-slides! mp))
        (set! last-load cur)
        (set! change? #t))))
  (define (refresh!)
    (when change?
      (define-values (actual-slide nearly-pict)
        (ST->slide-pict the-ST current-slide run-effect?))
      (set! run-effect? #f)
      (set! last-pict nearly-pict)
      (set! change? #f)))

  (load-mp!)

  (struct pres
    (g/v)
    #:methods gen:word
    [(define (word-label s ft)
       (lux-standard-label "Puresuri" ft))
     (define (word-event w e)
       (define closed? #f)
       (match e
         ['closed
          (set! closed? #t)]
         [(? (λ (x) (is-a? x key-event%)) ke)
          (define k (send ke get-key-code))
          (define h (ST-char-handler the-ST k))
          (cond
           [h
            (h)
            (set! change? #t)]
           [else
            (match k
              [(or #\q 'escape)
               (set! closed? #t)]
              [(or #\space 'right)
               (set! current-slide (add1 current-slide))
               (set! run-effect? #t)
               (set! change? #t)]
              [(or 'left)
               (set! current-slide (max 0 (sub1 current-slide)))
               (set! change? #t)]
              [#\i
               (set! current-slide
                     (if (= current-slide +inf.0)
                         0
                         +inf.0))
               (set! change? #t)]
              [_
               (void)])])]
         [_
          (void)])
       (cond
        [closed?
         #f]
        [else
         (load-mp!)
         (refresh!)
         w]))
     (define (word-tick w)
       (set! change? #t)
       (refresh!)
       w)
     (define (word-output w)
       ((pres-g/v w) last-pict))])

  (call-with-chaos
   (make-gui 2.0 #:width slide-w #:height slide-h)
   (λ ()
     (fiat-lux (pres (make-gui/val))))))

(define (load-slides! mp)
  (define new-ST (make-fresh-ST))
  (define ns (make-base-namespace))
  (namespace-attach-module (current-namespace) 'racket/gui/base ns)
  (namespace-attach-module (current-namespace) 'puresuri/main ns)
  (parameterize ([current-ST new-ST]
                 [current-namespace ns])
    (namespace-require `(file ,mp)))
  new-ST)

(define (ST->slide-pict st i run-effect?)
  (define base
    (colorize (filled-rectangle slide-w slide-h) "white"))
  (define-values (actual-slide almost-pict)
    (ST-cmds-interp st i run-effect? base))
  (define nearly-pict
    (clip
     (parameterize ([current-slide-number actual-slide])
       (ST-pipeline-apply st almost-pict))))
  (values actual-slide nearly-pict))

(define (ST->picts st)
  (let loop ([i 0])
    (define-values (ni p) (ST->slide-pict st i #f))
    (cons p (if (= i ni) empty (loop ni)))))

(define (puresuri->png-dir png-dir mp)
  (local-require racket/file
                 racket/format)
  (printf "Creating directory ~a\n" png-dir)
  (make-directory* png-dir)
  (printf "Loading slides...\n")
  (define the-ST (load-slides! mp))
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

(define (puresuri->pdf pdf-p mp)
  (local-require racket/file
                 racket/system)
  (define png-dir (make-temporary-file "~a-pngs" 'directory))
  (puresuri->png-dir png-dir mp)
  (define pngs (sort (map path->string (directory-list png-dir)) string-ci<=?))
  (define pdf.tex (build-path png-dir "pdf.tex"))
  (with-output-to-file pdf.tex
    (λ ()
      (displayln "\\documentclass{article}")
      (displayln "\\usepackage[active,tightpage]{preview}")
      (displayln "\\usepackage{graphicx}")
      (displayln "\\begin{document}")
      (for ([p (in-list pngs)])
        (displayln
         (format "\\begin{preview}\\includegraphics{~a}\\end{preview}" p)))
      (displayln "\\end{document}")))
  (dynamic-wind
    void
    (λ ()
      (parameterize ([current-directory png-dir])
        (system (format "pdflatex ~a" pdf.tex)))
      (copy-file (build-path png-dir "pdf.pdf") pdf-p #t))
    (λ ()
      (delete-directory/files png-dir))))

(module+ main
  (require racket/cmdline)

  (define operation puresuri!)

  (command-line
   #:program "puresuri"
   #:once-any
   [("--pngs") png-dir "Render as directory of pngs"
    (set! operation
          (λ (mp)
            (puresuri->png-dir png-dir mp)))]
   [("--pdf") pdf-p "Render as a PDF"
    (set! operation
          (λ (mp)
            (puresuri->pdf pdf-p mp)))]
   #:args (module-path)
   (cond
    [(file-exists? module-path)
     (operation module-path)]
    [else
     (error 'puresuri "File does not exist: ~e" module-path)])))
