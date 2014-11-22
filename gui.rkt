#lang racket/base
(require racket/contract/base
         racket/gui/base)

(define charcode/c
  (or/c char? key-code-symbol?))

(provide
 (contract-out
  [charcode/c contract?]))
