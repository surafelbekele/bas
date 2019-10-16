#!/bin/bash


#Using Sox to play a short jingle

play -n synth .25 tri C3 : synth .25 tri B3 : synth .25 sin E5 : synth .125 sin A4 : synth .125 sin A4

#Say command to introduce Bas the bash voice assistant

say hello i\'m baas   how can i help? 
say press space and say a short command like, What is the current weather? or Press X to leave

while true; do 

   read -rsn1 key


#Creates the request JSON file for the Google Speech API. This is overwritten per every request. 

FILENAME="request.json"
cat <<EOF > $FILENAME
{
  "config": {
    "encoding":"FLAC",
    "sampleRateHertz":16000,
    "profanityFilter": true,
    "languageCode": "en-US",
    "speechContexts": {
      "phrases": ['']
    },
    "maxAlternatives": 1
  },
  "audio": {
    "content":
	}
}
EOF

#Sets language to English

if [ $# -eq 1 ]
  then
    sed -i '' -e "s/en-US/$1/g" $FILENAME
fi


   if [[ "$key" = '' ]]; then 

   #Records 4 seconds of audio to flac and encrypts it to base64
      rec --channels=1 --bits=16 --rate=16000 audio.flac trim 0 4
      echo \"`base64 audio.flac`\" > audio.base64      
      sed -i '' -e '/"content":/r audio.base64' $FILENAME
   
   #Retrieves the response from the Google Speech API and writes it to JSON file response.json. This is overwritten per request. 
      curl -s -X POST -H "Content-Type: application/json" --data-binary @${FILENAME} https://speech.googleapis.com/v1/speech:recognize?key=<YOUR GOOGLE API KEY> -o response.json

   #jq parses the JSON file for the wanted content with the key transcript and saves it to a variable varsaid
      varsaid=`jq -r '.results[].alternatives[].transcript' response.json`

      if [[ ${varsaid} != "" ]]; then 
      #replaces the spaces within the query with "+"
         wolfsaid=${varsaid// /+}
         echo ${wolfsaid}
      #Creates the request Url for WolframAlpha's Spoken API 
         cleanwolf="https://api.wolframalpha.com/v1/spoken?i=${wolfsaid}%3F&appid=<YOUR WOLFRAM APP ID>"
      #Makes request and saves response from the Wolfram API to a variable   
         wolfresp=$(curl -s ${cleanwolf}) 
      #Uses say command to read the answer 
         say ${wolfresp}
         
      else 
         say can not execute command 
      fi
   fi  

   if [[ "$key" = 'x' ]]; then 
      say good bye
      break
   fi
done 


#References: (Sara Robinson) https://hackernoon.com/speech-to-text-transcription-in-40-lines-of-bash-f466092d8feb 
#           (jq)  https://stedolan.github.io/jq/tutorial/
#           (Wolfram API) https://products.wolframalpha.com/spoken-results-api/documentation/
