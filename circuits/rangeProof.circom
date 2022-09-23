pragma circom 2.0.0;

template RangeProof() {
    signal input salary;
    signal input times;
    signal input price;
    signal threshold;
    signal aux;
    signal output result;

    // Operations
    threshold <-- times*price;
    aux <-- threshold <= salary ? 1 : 0;  // 1 -> Your salary is greater than the requested threshold = times*price.
                                          // 0 -> Otherwise.

    // Constraints
    result <== aux*1 + 0; 
}

component main = RangeProof();