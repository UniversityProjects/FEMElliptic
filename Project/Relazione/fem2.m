%%%%%%%%%%%%%%%%%%%
% FEM for k = 2
%%%%%%%%%%%%%%%%%%%

clc
clear all
close all

% Exatc Solution Flag
  exact_solution = 'yes';
% exact_solution = 'no';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Mesh Creation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Domain Definition
omega = 'square'; % Unit Square
% omega = 'squareN'; % Unit Square With Neumann Conditions On A Border
% omega = 'igloo'; % Unit Square With Neumann Conditions On Half Border
% omega = 'squareCdisc'; % Disc With Neumann Conditions On Half Border

% Mesh Generator Choice
% meshgen = 'triangle'; % Mesh generated by triangle
  meshgen = 'uniform'; % Uniform mesh 

if (strcmp(meshgen, 'triangle'))
    % Build The Triangle Mesh
    disp('--- Building Mesh ---');
    makemesh;

    % Read The Triangle Mesh
    disp('--- Reading Mesh ---');
    readmesh;
    
else
    % Uniform Mesh
    disp('--- Building Uniform Mesh ---');
    makeuniform;
end

% List Mesh Details
disp(['      Vertex Number: ' num2str(nver)]);
disp(['      Triangles Number: ' num2str(nele)]);
disp(['      Edge Number: ' num2str(nedge)]);

% Plot The Mesh
disp('--- Drawing Mesh ---');
drawmesh;

% Quadrature Formula
fdq = 'degree=5';

% (xhq, yhq) Quadrature's Nodes
% whq = pesi
disp('--- Quadrature Computation ---');
disp([' quadrature: ', fdq]); 
[xhq,yhq,whq] = quadrature(fdq);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Kh Matrix Assembling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Basis Function Computed On The Quadrature Nodes Of The Riferement Element

Nq = length(xhq); % Number Of Quadrature Nodes
phihq = zeros(6,Nq); % Phihq Definition
gphihqx = zeros(6,Nq); % Gradphihq Definition
gphihqy = zeros(6,Nq); % Gradphihq Definition

% Basis Functions Computation Loop
disp('--- Basis Functions Phi Computation ---');
for i=1:6
    for q=1:Nq
        phihq(i,q) = phih2(i,xhq(q),yhq(q));
    end
end

% Basis Functions Gradients Computation Loop
disp('--- Gradient Basis Functions Phi Computation ---');
for i=1:6
    for q=1:Nq
        [gx gy] = gradphih2(i,xhq(q),yhq(q));
        gphihqx(i,q) = gx;
        gphihqy(i,q) = gy;
    end
end

% A Matrix Definition
A = sparse(nver+nedge,nver+nedge);

% b Array Definition
b = zeros(nver+nedge,1);

% Main Computation Loop On Every Triangle
disp('--- A Matrix and b Array Computation ---');
for iele=1:nele
    
% Acquire Informations From The iele Elements
    
    % Vertices Acquisition
    v1 = vertices(iele,1);
    v2 = vertices(iele,2);
    v3 = vertices(iele,3);
    
    
    % Vertex 1 Coordinates
    x1 = xv(v1);
    y1 = yv(v1);
    
    % Vertex 2 Coordinates
    x2 = xv(v2);
    y2 = yv(v2);
    
    % Vertex 3 Coordinates
    x3 = xv(v3);
    y3 = yv(v3);  
    
    
 % Jacobian Matrix Computation
 
    % F Jacobian
    JF = [x2 - x1   x3 - x1
          y2 - y1   y3 - y1];
      
    % F Jacobian Inverse
    JFI = inv(JF);
    
    % F Jacobian Inverse Transpost
    JFIT = JFI';
    
    
% Single Element Area
    area = 0.5*det(JF);
    
% KE Matrix Definition   
    KE = zeros(6,6);
    
% Actual Matrix KE Computation Loop    
    for i=1:6
        for j=1:i-1 % Loop That Use Matrix Symmetry To Halve The Computations
            KE(i,j) = KE(j,i);
        end
        for j = i:6
            for q=1:Nq
                % Image on T (current triangle) Of The Quadrature Node
                % tmp = (xq, yq) = (xhq(q),yhq(q))
                % On The Riferiment Element
                tmp = JF*[xhq(q); yhq(q)] + [x1; y1];
                xq = tmp(1); % Quadrature Node X Coordinate
                yq = tmp(2); % Quadrature Node Y Coordinate
                % Diffusive term (Second Order)
                % c * grad phi(j,q) ** grad phi (i,q) * whq(q)
                diffusive = c(xq,yq)*dot(JFIT*[gphihqx(j,q);... 
                                               gphihqy(j,q)],...
                                         JFIT*[gphihqx(i,q);...
                                               gphihqy(i,q)]...
                                         )*whq(q);
                % Reactive Term (First Order)
                % beta ** grad phi(j,q) * phi (i,q) * whq(q)
                [b1, b2] = beta(xq,yq);
                transport = dot([b1; b2], ...
                                JFIT*[gphihqx(j,q); gphihqy(j,q)]...
                                )*phihq(i,q)*whq(q);
                % Transport Term (Zeroth Order)
                % alpha * phi(j,q) * phi (i,q) * whq(q)
                reaction = alpha(xq,yq)*(phihq(j,q)*phihq(i,q))*whq(q);
                % KE(i,j) Sum Update With All Three Terms
                KE(i,j) = KE(i,j) + diffusive + transport + reaction;            
            end
            KE(i,j) = 2*area*KE(i,j);
        end
    end

% Recover Triangle's Edges
    l1 = edges(iele,1); % First Edge
    l2 = edges(iele,2); % Second Edge
    l3 = edges(iele,3); % Third Edge

% Global Degrees Of Freedon

    % Vertex i ---> i
    % Edge i   ---> nver
    % This array gives the current triangle's Global Degrees Of Freedom
    dofg = [v1 v2 v3 (nver+l1) (nver+l2) (nver+l3)];


% Global Matrix A Computation
    A(dofg,dofg) = A(dofg,dofg) + KE;
    
    
% FE Array Definition   
    FE = zeros(6,1);
    
% Actual Array Fe Computation Loop  
    for i=1:6
        for q=1:Nq
            % Image on T (current triangle) Of The Quadrature Node
            % tmp = (xq, yq) = (xhq(q),yhq(q))
            tmp = JF*[xhq(q); yhq(q)] + [x1; y1];
            xq = tmp(1); % Quadrature Node X Coordinate
            yq = tmp(2); % Quadrature Node Y Coordinate
            FE(i) = FE(i) + f(xq,yq)*phihq(i,q)*whq(q);        
        end
        FE(i) = 2*area*FE(i);
    end

% Global b Coefficient Computation
    b(dofg) = b(dofg) + FE;
    
    
end

% Spy A Matrix
disp('--- Spying A matrix ---');
figure();
spy(A);


 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Border Conditions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('--- Border Conditions ---');

% Free Nodes Array Definition
NL = [];

% Approximated Solution Array Definition
uh = zeros(nver+nedge,1);

for iv=1:nver
    % Check if the iv vertex is a border vertex
    if (vertexmarker(iv) == 1) % Dirichlet Condition
        uh(iv) = g(xv(iv),yv(iv));
        % Update Constant Term
        b = b - uh(iv)*A(:,iv);
    else % Free Node
        NL = [NL iv];
    end    
end


for iedge=1:nedge  
    % Border Degree Of Freedom
    dof = nver+iedge;  
    % Constant Term Update    
    if edgemarker(iedge)==1 % Border Edge
    % Edge Medium Point 
        % First Point
        v1 = endpoints(iedge,1);
        x1 = xv(v1);
        y1 = yv(v1);
        % Second Point
        v2 = endpoints(iedge,2);
        x2 = xv(v2);
        y2 = yv(v2);
        % Medium Point Computation
        xm = (x1 + x2) / 2;
        ym = (y1 + y2) / 2;
    % Constant Tern Update
        uh(dof) = g(xm,ym);
        b = b -uh(dof)*A(:,dof);
    else % Free Edge       
        NL = [NL dof];        
    end    
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Approximate Solution Computation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('--- Solution Computing ---');

% Exctract The True Kh Matrix On The Free Nodes
Kh = A(NL,NL);

% Exctract The True fh Array On The Free Nodes
fh = b(NL);

% Compute The Approximated Solution
% If iv is a vertex, then uh(iv) is the value
% of uh in that vertex.
% if ie is an edge, uh(nver+ie) is the value
% of uh in the medium point of the edge.
uh(NL) = Kh\fh;

% Solution Plot On Vertices
disp('--- Drawing Approximated Solution On Vertices---');
drawuhVer;

% Solution Plot
disp('--- Drawing Approximated Solution On Edges---');
drawuhEdge;

% Uh Max
disp(['--- Uh max: ' num2str(max(uh)) ' ---']);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Exact Solution Plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (strcmp(exact_solution,'yes'))
    % Exact Solution Plot On Vertices
    disp('--- Drawing Exact Solution On Vertices---');
    %drawueVer;

    % Exact Solution Plot
    disp('--- Drawing Exact Solution On Edges---');
    drawueEdge;   
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% L2 and H1 Error Computation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (strcmp(exact_solution,'yes'))
    disp('--- L2 and H1 Error Computation ---');

    % Quadrature Formula For Error Computing
    fdq = 'degree=5';
    disp([' quadrature: ', fdq]); 

    % (xhq, yhq) Quadrature's Nodes
    % whq = pesi
    [xhq,yhq,whq] = quadrature(fdq);

    % Basis Function Computed On The Quadrature Nodes Of The Riferement Element

    Nq = length(xhq); % Number Of Quadrature Nodes
    phihq = zeros(6,Nq); % Phihq Definition
    gphihqx = zeros(6,Nq); % Gradphihq Definition
    gphihqy = zeros(6,Nq); % Gradphihq Definition

    % Basis Functions Computation Loop
    for i=1:6
      for q=1:Nq
            phihq(i,q) = phih2(i,xhq(q),yhq(q));
      end
    end

    % L2 Error Variable
    errL2sq = 0;
    
    % H1 Error Variable
    errH1sq = 0;
    
    % Actual Errors Computation
    % Works By Computing The Global Errors As A Summation
    % Of The Errors On Every Triangle    
    for iele=1:nele
    
    % Acquire Informations From The iele Elements
    
        % Vertices Acquisition
        v1 = vertices(iele,1);
        v2 = vertices(iele,2);
        v3 = vertices(iele,3);
    
    
        % Vertex 1 Coordinates
        x1 = xv(v1);
        y1 = yv(v1);
    
        % Vertex 2 Coordinates
        x2 = xv(v2);
        y2 = yv(v2);
    
        % Vertex 3 Coordinates
        x3 = xv(v3);
        y3 = yv(v3);  
    
    
    % Jacobian Matrix Computation
 
        % F Jacobian
        JF = [x2-x1   x3-x1
              y2-y1   y3-y1]; 
           
        % F Jabobian Inverse
        JFI = inv(JF);
     
        % F Jacobian Inverse Transosed   
        JFIT = JFI';
        
        % Single Element Area (Triangle's Area)
        area = (1/2)*det(JF);
    
    % Recover Triangle's Edges
        l1 = edges(iele,1); % First Edge
        l2 = edges(iele,2); % Second Edge
        l3 = edges(iele,3); % Third Edge

    % Global Degrees Of Freedon

        % Vertex i ---> i
        % Edge i   ---> nver
        % This row-array holds the current triangle's Global Degrees Of Freedom
        dofg = [v1 v2 v3 (nver+l1) (nver+l2) (nver+l3)];
    
    % Recover the uT coefficients
        uT = uh(dofg);
        
        % Tmp variables to hold the element result
        sqL2 = 0;
        sqH1 = [ 0; 0];
        normsqH1 = 0;
        
        % Computation Over Weighting Nodes
        for q=1:Nq
            % Compute the sum on phi(i)
            tmpL2 = 0; 
            tmpH1 = [0; 0];       
            for i=1:6
                tmpL2_1 = tmpL2 + uT(i)*phihq(i,q);
                tmpH1 = tmpH1 + JFIT*uT(i)*[gphihqx(i,q); gphihqy(i,q)];
            end
            % Error Computation
            tmpL2_2 = JF*[xhq(q);yhq(q)] + [x1;y1];
            xq = tmpL2_2(1);
            yq = tmpL2_2(2);            
            sqL2 = sqL2 + (ue(xq,yq) - tmpL2)^2 * whq(q);
            %sqH1 = sqH1 + [ux(xq,yq); uy(xq,yq)] - tmpH1;
            sqH1 = sqH1 + ue(xq,yq) - tmpH1;
            normsqH1 = normsqH1 + dot(sqH1, sqH1)*whq(q);
        end
    
        sqL2 = 2*area*sqL2;
        normsqH1 = 2*area*normsqH1;
        
        % L2 Error On The Element (Squared)
        errL2sq = errL2sq + sqL2;
        
        % H1 Error On The Element (Squared)
        % ErrH1 = errL2(u) + errL2(grad u)
        errH1sq = errH1sq + errL2sq + normsqH1;
        
    end  
    
    % Final L2 Error Computation
    errL2 = sqrt(errL2sq);
    
    % Final H1 Error Computation
    errH1 = sqrt(errH1sq);
    
    disp(['      L2 Error: ' num2str(errL2)]);
    disp(['      H1 Error: ' num2str(errH1)]);
    
    
end
    