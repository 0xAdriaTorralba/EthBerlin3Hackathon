pragma circom 2.0.0;

template AnnualSalaryProof() {
    signal input salary;
    signal input times;
    signal input threshold;
    signal aux;
    signal aux2;
    signal output result;

    // Operations
    aux <-- times*salary;
    aux2 <-- aux >= threshold ? 1 : 0;  // 1 -> You have more annual money than threshold.
                                        // 0 -> Otherwise.

    // Constraints
    result <== aux2*1 + 0; 
}

component main = AnnualSalaryProof();