function d=spdiag(vec)
% spdiag:   sparse diagonal matrix from a vector
% d=spdiag(vec)
d=sparse(1:length(vec),1:length(vec),vec);
