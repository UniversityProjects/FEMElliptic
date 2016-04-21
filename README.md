# FEMElliptic
Finite Element Methods For Elliptic Problems 

Uses the Matlab languages for the finite element implementation.

Uses the C library triangle

https://www.cs.cmu.edu/~quake/triangle.html

for 2D mesh generation.

-----
Lesson 1

 - Starting with the triangle library in Matlab.
 - Mesh Creation.
 - Mesh Acquisition In Matlab.
 - Mesh Drawing In Matlab.
 - Triangles Count In Plot.
 - Vertex Count In Plot.

-----
Lesson 2

-div(grad u) = f 	on omega
u = g 			    on omega's border

First Order Elements

 - KhTs Matrices Computation.
 - General Kh Matrix Computation (Memorized as a sparse matrix).
 - fhT Elements With Trapezoid And Barycenter Methods.
 - Fh Array Computation.
 - Border Condition Implementation.
 - Solution Computation.
 - Solution Plot.
 - Example with f = 1 and g = 0.

-----
Lesson 3

-div(c grad u) = f 	on omega
u = g 	on omega's border

First Order Elements

 - Added General Diffusion Term c(x,y)
 - c = 1
 - c = 2 + x + sin(3y)
 - Added Neumann Conditions.
 - Discontinuous c(x,y) Example (With Mesh That Follows The Discontinuity).
 - Added Exact Solution Confront.
 - Added An Order 2 Formula For Numerical Integration.
 
 
-div(c grad u) + alpha*u = f 	on omega
u = g 	on omega's border

 - Added general reaction term alpha.


-----
Lesson 4

-div(c grad u) = f 	on omega

Second Order Elements

PART I

 - Added mesh details for finite elements of order K = 2.
   (See http://arxiv.org/abs/math/0501496v2 for quadrature formula)
 - Added KE partial coefficients matrix computation.

 


