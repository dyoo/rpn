#lang planet dyoo/whalesong

(provide (struct-out calc)
         insert-digit)

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


;; insert-digits: calc (listof number) -> calc
;; Convenience function to inserting multiple digits into the calculator at once.
(define (insert-digits calc digits)
  (foldl (lambda (digit calc)
           (insert-digit calc digit))
         calc
         digits))


(check-expect (insert-digit THE-EMPTY-CALCULATOR 1)
              (make-calc '() '(1)))

(check-expect (insert-digit THE-EMPTY-CALCULATOR 0)
              (make-calc '() '(0)))

(check-expect (insert-digit (insert-digit THE-EMPTY-CALCULATOR 1)
                            2)
              (make-calc '() '(1 2)))

;; If we press zero multiple times before starting to add numbers in,
;; nothing should show up on the display...
(check-expect (insert-digits THE-EMPTY-CALCULATOR
                             '(0 0 3 1 4 1 5 9 2 6))
              (make-calc '()
                         '(3 1 4 1 5 9 2 6)))

;; but of course, zero should be significant once we start
;; entering numbers.
(check-expect (insert-digits THE-EMPTY-CALCULATOR
                             '(0 0 3 0 0))
              (make-calc '()
                         '(3 0 0)))