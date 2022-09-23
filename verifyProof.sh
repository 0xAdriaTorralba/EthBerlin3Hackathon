if [ $1 = "-h" ]; then
    echo "Usage: sh verifyProof.sh <circuit name>"
    exit
fi
snarkjs groth16 verify output_files_$1/$1_verification_key.json public.json proof.json