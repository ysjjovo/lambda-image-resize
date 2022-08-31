CodeBucket=lings3
baseDir=$(shell pwd)
reqDir=${baseDir}/lambda/viewer-request-function
resDir=${baseDir}/lambda/origin-response-function
# region=$(aws configure get region)
stack_name=imageResize
cf=cf.yml
install:
	cd ${reqDir} && npm init -f -y && npm install querystring -S
	cd ${resDir} && npm init -f -y && npm install sharp querystring -S

zipReq:
	mkdir -p ${baseDir}/dist && cd ${reqDir} && zip -qr ${baseDir}/dist/viewer-request-function.zip *
zipRes:
	mkdir -p ${baseDir}/dist && cd ${resDir} && zip -qr ${baseDir}/dist/origin-response-function.zip *
zip: zipReq zipRes

upload: zip
	cp ${baseDir}/cf.yml ${baseDir}/dist/
	aws s3 cp --recursive ${baseDir}/dist s3://${CodeBucket}
	# aws s3api put-object --bucket ${CodeBucket} --key ${cf} --body ${baseDir}/${cf} > /dev/null
cf: upload
	aws cloudformation create-change-set --change-set-type CREATE --stack-name ${stack_name} --change-set-name ${stack_name} --template-url https://${CodeBucket}.s3.amazonaws.com/${cf} --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM --parameters ParameterKey="CodeBucket",ParameterValue=${CodeBucket} > /dev/null
	aws cloudformation wait change-set-create-complete --stack-name ${stack_name} --change-set-name ${stack_name} 
	aws cloudformation execute-change-set --change-set-name ${stack_name} --stack-name ${stack_name}
req:
	curl https://d2mwbbimj0dc7u.cloudfront.net/images/21.jpg?d=100x100

