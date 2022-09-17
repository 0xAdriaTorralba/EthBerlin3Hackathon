pragma circom 2.0.0;

template LegalAgeProof() {
    signal input age;
    signal input legalAge;
    signal aux;
    signal output result;

    // Operations
    aux <-- age - legalAge >= 0 ? 1 : 0; // 1 -> You are of legal age.
                                   // 0 -> Otherwise.

    result <== aux*1 + 0;


}

component main = LegalAgeProof();