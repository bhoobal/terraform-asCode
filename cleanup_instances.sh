#!/bin/bash -e
# Get a list of subfolders under the  folder
bucket_path="s3://vsupport/governance/deleteec2/"
dates=$(aws s3 ls ${bucket_path}|awk '{print $2}'|sed 's/\///g')
# Get a nicely formatted date string which matches the format of subfolders (YYYYMMDD)
today=$(date +%Y%m%d)
# For each interview date...
for d in $dates; do
  # If the date is prior to today, terminate
  if [[ $d -lt $today ]]; then
    aws s3 sync ${bucket_path}${d}/ "$d"
    # If $d is not empty, continue
    if [[ ! -z "$(ls -A ${d})" ]]; then
      pushd "$d"
        # Get a list of candidate names
        for name in */; do
          pushd "${name}"
            echo "Working on $d - $name"
            # Copy our stub terraform file to prevent the need for specifying parameters.
            cp ../../stub.tf .
            terraform init
            terraform destroy --force -var-file=../../../../Global.tfvars
          popd
        done
      popd
      # Cleanup local dir and bucket subfolder
      rm -fr "$d"
      aws s3 rm "${bucket_path}${d}" --recursive
    else
      echo "${d} is empty"
      rm -fr "$d"
      aws s3 rm "${bucket_path}${d}" --recursive
    fi
  fi
done
