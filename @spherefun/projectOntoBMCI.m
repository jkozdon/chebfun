function f = projectOntoBMCI( f )
% PROJECTONTOBMCI  Projection onto BMC-I symmetry.
%
% g = projectOntoBMCI(f) is the orthogonal projection of f onto BMC-I 
% symmetry, i.e., a function that is
% 1. even in theta for every even wave number in lambda;
% 2. odd in theta for every odd wave number in lambda;
% Additionally, for all but k=0 wavenumber lambda the resulting projection
% enforces the spherefun is zero at the poles. 
%
% The projection is orthogonal, i.e., the correction matrix to fix up the
% structure has the smallest possible Frobenius norm.

[fp,fm] = partition( f );

fp = projectOntoEvenBMCI( fp );
fm = projectOntoOddBMCI( fm );

% Put pieces back together.
f = combine(fp,fm);

end

function f = projectOntoEvenBMCI( f )
% Project a spherefun to have even BMC-I symmetry, i.e., a spherefun that
% is pi-periodic in lambda and even in theta. The projection is orthogonal,
% i.e., the correction matrix to fix up the structure has the smallest
% possible Frobenius norm.

% Nothing to project
if isempty( f )
    return;
end

% Operate on the column coefficients first to project them onto even
% functions.
X = f.cols.funs{1}.onefun.coeffs;

% Get size: 
[m, n] = size(X); 

isevenM = false;
if mod(m,2) == 0
    X(1,:) = 0.5*X(1,:);
    X = [X;X(1,:)];
    m = m+1;
    isevenM = true;
end

% Only project the nonzero Fourier modes:
waveNumbers = -(m-1)/2:(m-1)/2;

evenModes = 1:n;
A = [];
if f.nonZeroPoles
    zeroMode = 1;
    % Need to handle the zero mode in lambda separately
    % Enforce the expansion is even in theta
    I = eye(m); A = I - fliplr(I); A = A(1:(m-1)/2,:);
    % Solution to underdetermined system A*(X + Y) = 0 with smallest Frobenius
    % norm: 
    C = A\(A*X(:,zeroMode));

    % Update coeff matrix: 
    X(:,zeroMode) = X(:,zeroMode) - C; 

    % The result of the code now needs to operate on the remaining even,
    % non-zero modes.
    evenModes = 2:n;
end

% Second do the even, non-zero modes in lambda
% Enforce these are zero at the poles and that the expansion is even in 
% theta
A = [[ones(1,m); (-1).^waveNumbers];A];

% Solution to underdetermined system A*(X + Y) = 0 with smallest Frobenius
% norm: 
C = A\(A*X(:,evenModes));

% Update coeff matrix: 
X(:,evenModes) = X(:,evenModes) - C; 

% If m is even we need to remove the mode that was appended 
if ( isevenM )
    X(1,:) = (X(1,:)+X(end,:));
    X = X(1:m-1,:);
end

ctechs = real(trigtech({'',X}));
f.cols.funs{1}.onefun = ctechs;

% Now operate on the rows. The coefficients for the rows of an even BMCI
% function should only contain even wave numbers. The projection is to
% simply zero out the odd wave numbers.
X = f.rows.funs{1}.onefun.coeffs;
n = size(X,1); 
zeroMode = floor(n/2)+1;
oddModes = [fliplr(zeroMode-1:-2:1) zeroMode+1:2:n];
X(oddModes,:) = 0;
rtechs = real(trigtech({'',X}));
f.rows.funs{1}.onefun = rtechs;

% Weird feval behavior in chebfun requires this
f.cols.pointValues = feval(ctechs,[-1;1]);
f.rows.pointValues = feval(rtechs,[-1;1]); 

end

function f = projectOntoOddBMCI( f )
% Project a spherefun to have odd BMC-I symmetry, i.e., a spherefun that is
% pi-anti-periodic in lambda and even in theta. The projection is
% orthogonal, i.e., the correction matrix to fix up the structure has the
% smallest possible Frobenius norm.

% Nothing to project
if isempty( f )
    return;
end

% Operate on the column coefficients first to project them onto odd
% functions.
X = f.cols.funs{1}.onefun.coeffs;

% Get size: 
m = size(X,1);

isevenM = false;
if mod(m,2) == 0
    X(1,:) = 0.5*X(1,:);
    X = [X;X(1,:)];
    m = m+1;
    isevenM = true;
end

I = eye(m); A = I + fliplr(I); 
A = A(1:(m-1)/2+1,:); A((m-1)/2+1,(m-1)/2+1) = 1;

% Solution to underdetermined system A*(X + Y) = 0 with smallest Frobenius
% norm: 
C = A\(A*X);
% Update coeff matrix: 
X = X - C; 

% If m is even we need to remove the mode that was appended 
if ( isevenM )
    X(1,:) = (X(1,:)+X(end,:));
    X = X(1:m-1,:);
end

ctechs = real(trigtech({'',X}));
f.cols.funs{1}.onefun = ctechs;

% Now operate on the rows. The coefficients for the rows of an odd BMCI
% function should only contain odd wave numbers. The projection is to
% simply zero out the even wave numbers.
X = f.rows.funs{1}.onefun.coeffs;
n = size(X,1); 
zeroMode = floor(n/2)+1;
evenModes = [fliplr(zeroMode-2:-2:1) zeroMode:2:n];
X(evenModes,:) = 0;

rtechs = real(trigtech({'',X}));
f.rows.funs{1}.onefun = rtechs;

% Weird feval behavior in chebfun requires this
f.cols.pointValues = feval(ctechs,[-1;1]);
f.rows.pointValues = feval(rtechs,[-1;1]); 

end