#lang whalesong/base

;; calc is a model of the calculator .
(define-struct calc (stack ;; (listof number)
                     onscreen ;; (listof number)
                     ))

(define THE-EMPTY-CALCULATOR
  (make-calc '() '(0)))

;; insert-digit: calc number -> calc
;; Enters a digit on the calculator
(define (insert-digit calc digit)
  (make-calc (calc-stack calc)
             (cond
              [(equal? (calc-onscreen calc) '(0))
               (list digit)]
              [else
               (append (calc-onscreen calc) (list digit))])))

(check-expect 