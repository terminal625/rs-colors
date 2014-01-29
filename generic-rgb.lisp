;;; generic-rgb.lisp --- generic RGB color space.

;; Copyright (C) 2014 Ralph Schleicher

;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions
;; are met:
;;
;;    * Redistributions of source code must retain the above copyright
;;      notice, this list of conditions and the following disclaimer.
;;
;;    * Redistributions in binary form must reproduce the above copyright
;;      notice, this list of conditions and the following disclaimer in
;;      the documentation and/or other materials provided with the
;;      distribution.
;;
;;    * The name of the author may not be used to endorse or promote
;;      products derived from this software without specific prior
;;      written permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS
;; OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
;; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;; ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
;; INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
;; (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
;; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
;; HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
;; STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
;; IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
;; POSSIBILITY OF SUCH DAMAGE.

;;; Code:

(in-package :rs-colors)

(export 'rgb-color)
(defclass rgb-color (color)
  ((r
    :initarg :red
    :initform 0
    :type (real 0 1)
    :documentation "Intensity of the red primary, default zero.")
   (g
    :initarg :green
    :initform 0
    :type (real 0 1)
    :documentation "Intensity of the green primary, default zero.")
   (b
    :initarg :blue
    :initform 0
    :type (real 0 1)
    :documentation "Intensity of the blue primary, default zero."))
  (:documentation "Color class for a RGB color space."))

(defmethod color-coordinates ((color rgb-color))
  (with-slots (r g b) color
    (values r g b)))

(export 'hsv-color)
(defclass hsv-color (color)
  ((h
    :initarg :hue
    :initform 0
    :type (real 0 (360))
    :documentation "Hue, default zero.")
   (s
    :initarg :saturation
    :initform 0
    :type (real 0 1)
    :documentation "Saturation, default zero.")
   (v
    :initarg :value
    :initform 0
    :type (real 0 1)
    :documentation "Value (brightness), default zero."))
  (:documentation "Color class for the HSV/HSB color space."))

(defmethod color-coordinates ((color hsv-color))
  (with-slots (h s v) color
    (values h s v)))

(export 'hsl-color)
(defclass hsl-color (color)
  ((h
    :initarg :hue
    :initform 0
    :type (real 0 (360))
    :documentation "Hue, default zero.")
   (s
    :initarg :saturation
    :initform 0
    :type (real 0 1)
    :documentation "Saturation, default zero.")
   (l
    :initarg :lightness
    :initform 0
    :type (real 0 1)
    :documentation "Lightness, default zero."))
  (:documentation "Color class for the HSL color space."))

(defmethod color-coordinates ((color hsl-color))
  (with-slots (h s l) color
    (values h s l)))

;; HSV/HSB, HSL, or HSI from RGB.
(macrolet ((with-hue (bindings &body body)
	     `(let* ((max (max r g b))
		     (min (min r g b))
		     ;; Chroma.
		     (c (- max min))
		     ;; Hue.
		     (h (if (zerop c)
			    0
			  (mod (* 60 (cond ((= r max)
					    (+ 0 (/ (- g b) c)))
					   ((= g max)
					    (+ 2 (/ (- b r) c)))
					   ((= b max)
					    (+ 4 (/ (- r g) c)))
					   (t
					    (error "Should not happen."))))
			       360)))
		     ,@bindings)
		,@body)))
  (defun hsv-from-rgb (r g b)
    "Convert RGB color space coordinates
into HSV color space coordinates."
    (declare (type real r g b))
    (with-hue (;; Value (brightness).
	       (v max)
	       ;; Saturation.
	       (s (if (zerop c)
		      0
		    (/ c v))))
      (values h s v)))
  (defun hsl-from-rgb (r g b)
    "Convert RGB color space coordinates
into HSL color space coordinates."
    (declare (type real r g b))
    (with-hue (;; Lightness.
	       (2l (+ min max))
	       (l (/ 2l 2))
	       ;; Saturation.
	       (s (if (zerop c)
		      0
		    ;; The denominator can also be
		    ;; expressed as 1 - |2L - 1|.
		    (/ c (if (> 2l 1) (- 2 2l) 2l)))))
      (values h s l)))
  (defun hsi-from-rgb (r g b)
    "Convert RGB color space coordinates
into HSI color space coordinates."
    (declare (type real r g b))
    (with-hue (;; Intensity.
	       (i (/ (+ r g b) 3))
	       ;; Saturation.
	       (s (if (zerop c)
		      0
		    (- 1 (/ min i)))))
      (values h s i)))
  (values))

;; RGB from HSV/HSB or HSL.
(macrolet ((with-chroma (chroma value)
	     `(let* ((c ,chroma)
		     ;; Extrema.
		     (max ,value)
		     (min (- max c)))
		(multiple-value-bind (q r)
		    (truncate (/ h 60))
		  (let ((x (- max (* c (if (oddp q) r (- 1 r))))))
		    (cond ((= q 0) (values max x min))
			  ((= q 1) (values x max min))
			  ((= q 2) (values min max x))
			  ((= q 3) (values min x max))
			  ((= q 4) (values x min max))
			  ((= q 5) (values max min x))
			  (t
			   (error "Should not happen."))))))))
  (defun rgb-from-hsv (h s v)
    "Convert HSV color space coordinates
into RGB color space coordinates."
    (declare (type real h s v))
    (if (zerop s)
	(values v v v)
      (with-chroma (* s v)
	v)))
  (defun rgb-from-hsl (h s l)
    "Convert HSL color space coordinates
into RGB color space coordinates."
    (declare (type real h s l))
    (if (zerop s)
	(values l l l)
      (let ((2l (* 2 l)))
	(declare (type real 2l))
	(with-chroma (* s (if (> 2l 1) (- 2 2l) 2l))
	  (+ l (/ c 2))))))
  (values))

(export 'rgb-color-coordinates)
(defgeneric rgb-color-coordinates (color)
  (:documentation "Return the RGB color space coordinates of the color.

Argument COLOR is a color object.

Values are the intensities of the red, green, and blue primary.")
  (:method ((color rgb-color))
    (color-coordinates color)))

(export 'hsv-color-coordinates)
(defgeneric hsv-color-coordinates (color)
  (:documentation "Return the HSV color space coordinates of the color.

Argument COLOR is a color object.

Values are the hue, saturation, and value (brightness).")
  (:method ((color hsv-color))
    (color-coordinates color))
  (:method ((color color))
    (multiple-value-call #'hsv-from-rgb
      (rgb-color-coordinates color))))

(export 'hsl-color-coordinates)
(defgeneric hsl-color-coordinates (color)
  (:documentation "Return the HSL color space coordinates of the color.

Argument COLOR is a color object.

Values are the hue, saturation, and lightness.")
  (:method ((color hsl-color))
    (color-coordinates color))
  (:method ((color color))
    (multiple-value-call #'hsl-from-rgb
      (rgb-color-coordinates color))))

;;; generic-rgb.lisp ends here