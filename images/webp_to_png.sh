#!/bin/bash

convert_image() {
  local input_file=$1
  local output_file=$2
  local input_checksum=$3

  # Convert the file from .webp/.jpg to .png and remove the white background
  convert "$input_file" -fuzz "$FUZZ" -transparent white "$output_file"

  echo "Converted and background removed: ${input_file} to ${output_file}"
  
  # Update the checksum file with the new checksum
  # First remove any existing entry with the same basename
  sed -i "/${base_filename}:/d" "${CHECKSUM_FILE}"
  # Append the new checksum to the file
  echo "${base_filename}:${input_checksum}" >> "${CHECKSUM_FILE}"
}

# Get the directory where the script is located
SOURCE_DIR="$(dirname "$0")"

# Directory to save the converted .png files
TARGET_DIR="${SOURCE_DIR}/converted_pngs"

# Hidden file to store SHA-256 checksums of processed files
CHECKSUM_FILE="${TARGET_DIR}/checksums"

# Tolerance for removing the white background
FUZZ="10%"

# Create target directory if it doesn't exist
mkdir -p "${TARGET_DIR}"

# Touch the checksum file to ensure it exists
touch "${CHECKSUM_FILE}"

# Function to process each file
process_file() {
  local file=$1
  local extension=$2
  # Calculate the SHA-256 checksum of the current file
  local checksum=$(sha256sum "$file" | awk '{print $1}')
  
  # Extract the basename of the file for the converted filename and the checksum comparison
  local base_filename=$(basename "${file}" .${extension})
  
  # Check if the checksum is different from the stored checksum or if it doesn't exist
  if ! grep -q "${base_filename}:${checksum}" "${CHECKSUM_FILE}"; then
    # Construct the new filename with .png extension
    local newfile="${TARGET_DIR}/${base_filename}.png"
    
    # Call convert_image function
    convert_image "$file" "$newfile" "$checksum"
  else
    echo "No changes detected for ${file}, skipping conversion."
  fi
}

# Loop through all .webp and .jpg files in the source directory
for file in "${SOURCE_DIR}"/*.{webp,jpg}; do
  if [ -f "$file" ]; then
    if [[ "$file" == *.webp ]]; then
      process_file "$file" "webp"
    elif [[ "$file" == *.jpg ]]; then
      process_file "$file" "jpg"
    fi
  fi
done

echo "Conversion completed."
