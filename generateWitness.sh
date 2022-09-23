#!/bin/bash

# Variable to store the name of the circuit
CIRCUIT=rangeProof
AGE_CIRCUIT="legalAgeProof"
PREFIX=circuits/
NUM_PARAM=3
# Variable to store the number of the ptau file
PTAU=12

if [ "$1" = "-h" ]; then
    echo "Usage for 3 inputs: sh generateWitness.sh <circuit name> <salary> <times> <price>"
    echo "Usage for 1 input: sh generateWitness.sh <circuit name> <age>"
    exit
fi

# In case there is a circuit name as an input
if [ "$1" ]; then
    CIRCUIT=$1
fi

if [ "$CIRCUIT" = "$AGE_CIRCUIT" ]; then
    NUM_PARAM=1
    AGE=$2
    LEGAL_AGE=$3
fi

if [ "$2" ]; then
    SALARY=$2
fi

if [ "$3" ]; then
    TIMES=$3
fi

if [ "$4" ]; then
    PRICE=$4
fi

if [[ ${NUM_PARAM} == 1 ]]; then
    echo "1. Creating AGE input file..."
    echo '{"age":' ${AGE}', "legalAge":' ${LEGAL_AGE}'}' > input.json
    cp input.json ${CIRCUIT}_js/
    echo "Create input file OK!"
else
    echo "1. Creating OTHER input file..."
    echo '{"salary":' ${SALARY}', "times":' ${TIMES}', "price":' ${PRICE}'}' > input.json
    cp input.json ${CIRCUIT}_js/
    echo "Create input file OK!"
fi



# Check if the necessary ptau file already exists. If it does not exist, it will be downloaded from the data center
if [ -f ./ptau/powersOfTau28_hez_final_${PTAU}.ptau ]; then
    echo "----- powersOfTau28_hez_final_${PTAU}.ptau already exists -----"
else
    echo "----- Download powersOfTau28_hez_final_${PTAU}.ptau -----"
    wget -P ./ptau https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_${PTAU}.ptau
fi



echo "2. Compile the circuit..."
# Compile the circuit
circom ${PREFIX}${CIRCUIT}.circom --r1cs --wasm --sym --c
rm -rf output_files_${CIRCUIT}
rm -rf compiled
mkdir output_files_${CIRCUIT}
mkdir compiled
mkdir compiled/${CIRCUIT}_js
mkdir compiled/${CIRCUIT}_cpp
mv ${CIRCUIT}.r1cs output_files_${CIRCUIT}/${CIRCUIT}.r1cs
mv ${CIRCUIT}.sym output_files_${CIRCUIT}/${CIRCUIT}.sym


mv ${CIRCUIT}_js/* compiled/${CIRCUIT}_js
mv ${CIRCUIT}_cpp/* compiled/${CIRCUIT}_cpp
echo "Compile the circuit OK!"




echo "3. Generate witness..."
# Generate the witness.wtns
node compiled/${CIRCUIT}_js/generate_witness.js compiled/${CIRCUIT}_js/${CIRCUIT}.wasm input.json output_files_${CIRCUIT}/witness.wtns
mv compiled/${CIRCUIT}_js/${CIRCUIT}.wasm output_files_${CIRCUIT}/${CIRCUIT}.wasm

echo "Generate witness OK!"


echo "4. Starting Power of Tau..."
# Power of Tau
snarkjs powersoftau new bn128 12 ptau/pot12_0000.ptau
snarkjs powersoftau contribute ptau/pot12_0000.ptau ptau/pot12_0001.ptau --name="First contribution"
echo "Power of Tau OK!"


echo "5. Contribute to power of Tau..."
snarkjs powersoftau prepare phase2 ptau/pot12_0001.ptau ptau/pot12_final.ptau
echo "Contribute to power of Tau OK!"



echo "6. Contribute to phase 2 of the ceremony..."
# Contribute to the phase 2 of the ceremony
snarkjs groth16 setup output_files_${CIRCUIT}/${CIRCUIT}.r1cs ptau/pot12_final.ptau output_files_${CIRCUIT}/${CIRCUIT}_0000.zkey
echo "here"
snarkjs zkey contribute output_files_${CIRCUIT}/${CIRCUIT}_0000.zkey output_files_${CIRCUIT}/${CIRCUIT}_final.zkey --name="1st Contributor Name" -v -e="ethberlin3"
echo "Contribute to phase 2 OK!"


echo "7. Export the verification key..."
# Export the verification key
snarkjs zkey export verificationkey output_files_${CIRCUIT}/${CIRCUIT}_final.zkey output_files_${CIRCUIT}/${CIRCUIT}_verification_key.json
echo "Export the verification key OK!"

echo "8. Generate zk-proof"
# Generate a zk-proof associated to the circuit and the witness. This generates proof.json and public.json
snarkjs groth16 prove output_files_${CIRCUIT}/${CIRCUIT}_final.zkey output_files_${CIRCUIT}/witness.wtns proof.json public.json
echo "Generate zk-proof OK!"


echo "9. Verify the proof..."
# Verify the proof
snarkjs groth16 verify output_files_${CIRCUIT}/${CIRCUIT}_verification_key.json public.json proof.json
echo "Verify the proof OK!"



echo "10. Generate Solidity verifier..."
# Generate a Solidity verifier that allows verifying proofs on Ethereum blockchain
snarkjs zkey export solidityverifier output_files_${CIRCUIT}/${CIRCUIT}_final.zkey output_files_${CIRCUIT}/${CIRCUIT}Verifier.sol
# Update the solidity version in the Solidity verifier
sed -i 's/0.6.11;/0.8.4;/g' output_files_${CIRCUIT}/${CIRCUIT}Verifier.sol
# Update the contract name in the Solidity verifier
sed -i "s/contract Verifier/contract ${CIRCUIT}Verifier/g" ${CIRCUIT}Verifier.sol
echo "Generate Solidity verifier OK!"


echo "11. Generate and print parameters of call..."
# Generate and print parameters of call
snarkjs generatecall | tee parameters.txt > output_files_${CIRCUIT}/${CIRCUIT}_result.txt
echo "Generate and print parameters OK!"
