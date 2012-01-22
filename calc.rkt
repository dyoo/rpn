#lang planet dyoo/whalesong

(provide (struct-out calc)
         insert-digit
         press
         digits->number)

;; calc is a model of the calculator .
(define-struct calc (stack ;; (listof number)
                     onscreen ;; (listof number)
                     ))

(define INIT-CALC
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

(check-expect (insert-digit INIT-CALC 1)
              (make-calc '() '(1)))

(check-expect (insert-digit INIT-CALC 0)
              (make-calc '() '(0)))

(check-expect (insert-digit (insert-digit INIT-CALC 1)
                            2)
              (make-calc '() '(1 2)))



;; A command is a number, or the symbol 'enter.

;; press: calc (listof command) -> calc
;; Convenience function doing multiple commands into the calculator at once.
(define (press calc commands)
  (foldl (lambda (cmd calc)
           (cond
            [(number? cmd)
             (insert-digit calc cmd)]
            [(eq? cmd 'enter)
             (push-stack calc)]
            [else
             (error 'press "Unknown command: ~e" cmd)]))
         calc
         commands))


;; If we press zero multiple times before starting to add numbers in,
;; nothing should show up on the display...
(check-expect (press INIT-CALC
                             '(0 0 3 1 4 1 5 9 2 6))
              (make-calc '()
                         '(3 1 4 1 5 9 2 6)))

;; but of course, zero should be significant once we start
;; entering numbers.
(check-expect (press INIT-CALC
                             '(0 0 3 0 0))
              (make-calc '()
                         '(3 0 0)))




;; digits->number: (listof number) -> number
;; Take the digits and condense them into a single number.
(define (digits->number digits)
  (foldl (lambda (digit acc)
           (+ (* acc 10) digit))
         0
         digits))

(check-expect (digits->number '(0))
              0)

(check-expect (digits->number '(4 2))
             42)

(check-expect (digits->number '(1 2 3 4))
              1234)



;; push-stack: calc -> calc
;; Put the number in the onscreen window onto the stack,
;; and reset the onscreen back to '(0).
(define (push-stack calc)
  (make-calc (cons (digits->number (calc-onscreen calc))
                   (calc-stack calc))
             '(0)))

(check-expect (push-stack INIT-CALC)
              (make-calc '(0)
                         '(0)))

(check-expect (push-stack (push-stack INIT-CALC))
              (make-calc '(0 0)
                         '(0)))

(check-expect (push-stack
               (press
                (push-stack
                 (press INIT-CALC '(3 1 4)))
                '(4 5 6)))
              (make-calc '(456 314)
                         '(0)))

;; We rewrite the test to use 'enter:
(check-expect (press INIT-CALC '(3 1 4 enter 4 5 6 enter))
              (make-calc '(456 314)
                         '(0)))

