RETRYABLE=0
REASON=''

# end_job sends an slack notification and call an api to kill this job
end_job () {
    echo "Sending Slack notification"
    curl -X POST -H 'Content-type: application/json' 
    --data '{	
        "attachments": [
            {
                "fallback": "Required plain-text summary of the attachment.",
                "color": "#cc0000",
                "pretext": "Error en job '${jobid}'",
                "author_name": "Rundeck",
                "title": "Job Fallido",
                "title_link": "http://3.94.225.3:4440/project/Test/execution/show/'${jobid}'",
                "text": "El job '${jobid}' fue detenido debido a '$(echo $*)'",
                "fields": [
                    {
                        "title": "Priority",
                        "value": "High",
                        "short": false
                    }
                ],
                "footer": "Data Notificator bot"
            }
        ]
    }' https://hooks.slack.com/services/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
    echo "Killing job"
    curl http://10.55.10.173:4440/api/21/execution/${jobid}/abort --header "X-Rundeck-Auth-Token: C3A29QypKrovDef9EqH7vRaF9w5oqGUn" --header 'Content-Type: application/json'
}

if [ -f $log ]; then
    echo "Log found"
else
    echo "Log not found"
    REASON="no encontre el log '${log}'"
    exit 1
fi

echo "Looking for Postgres issue: user holding a relation lock"
if  grep -q "Detail: User was holding a relation lock for too long." $log; then
    echo "Found issue"
    RETRYABLE=1
    REASON="Detail: User was holding a relation lock for too long"
fi

echo "Looking for Postgres issue: Error connecting to database"
if  grep -q "Error connecting to database" $log; then
    echo "Found issue"
    RETRYABLE=1
    REASON="Detail: Error connecting to database"
fi

echo "Looking for Pentaho issue: An I/O error occured while sending to the backend"
if  grep -q "An I/O error occured while sending to the backend" $log; then
    echo "Found issue"
    RETRYABLE=1
    REASON="Detail: An I/O error occured while sending to the backend"
fi

if [[ $RETRYABLE == 1 ]]; then
    echo "Must be retried"
    echo "Error reintentado: ${REASON}"
    exit 1
else
    REASON="no se detecto ningún error supervisado"
    echo "Error enviado: ${REASON}"
    end_job "${REASON}"
fi
exit 0
