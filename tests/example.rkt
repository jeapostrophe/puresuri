#lang racket/base
(require pict
         ppict-slide-grid
         puresuri
         puresuri/plpict
         unstable/gui/pict
         puresuri/lib/title
         puresuri/lib/grid
         puresuri/lib/cmds)
(module+ test)

(go! (relative-placer 1/2 1/2 'cc))
(add! plt-title-background)
(go! (relative-placer 1/2 1/2 'cc))
(add! (text "On Amazing Slideshows" null 60))
(go! (relative-placer 0.95 0.55 'rt))
(add! (text "Jay McCarthy" null 30))
(add! (text "Vassar & PLT" null 20))
(commit!)
(clear!)

(add! (text "What time is it?" null 60))
(commit!)
(add! (λ () (text (number->string (current-seconds)) null 60)))
(commit!)
(clear!)

(go! (relative-placer 0 0 'lt))
(add! #:tag 'circA (circle 20))
(go! (relative-placer 1 1 'rb))
(add! #:tag 'circB (circle 20))
(bind!
 (λ (p)
   (pin-arrow-line 10 p
                   (find-tag p 'circA) rb-find
                   (find-tag p 'circB) lt-find)))
(slide!)

(go! (relative-placer 1/2 0.1 'rt))
(add! #:tag 'red-fish (standard-fish 400 200 #:direction 'right #:color "red"))
(go! (relative-placer 1/2 1/2 'lt))
(add! #:tag 'blue-fish (standard-fish 500 300 #:direction 'left #:color "blue"))
(commit!)
(go! (at-placer 'red-fish rc-find 'lc))
(add! (text "red fish" null 60))
(commit!)
(go! (at-placer 'blue-fish lc-find 'rc))
(add! (text "blue fish" null 60))

(commit!)
(remove! 'blue-fish)

(commit!)
(go! (relative-placer 1/2 1/2 'lt))
(add! #:tag 'blue-fish (standard-fish 500 300 #:direction 'left #:color "green"))

(commit!)
(replace! 'red-fish (jack-o-lantern 50))

(slide!)

;; xxx add #:save and #:restore
