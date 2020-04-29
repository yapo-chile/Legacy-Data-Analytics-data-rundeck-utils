RETRYABLE=0
REASON=''

# end_job sends an email and call an api to kill this job
end_job () {
    echo "Sending email"
    curl --data '{
    "to": ["data_team@adevinta.com"],
    "subject": "Rundeck error en job '${jobid}'",
    "message": "Se encontro un error en rundeck, el proceso fue detenido",
    "html_message": "<h1>El job '${jobid}' fue detenido debido a '"$(echo $*)"'.</h1></br><h3>mas detalles en <a href='http://3.94.225.3:4440/project/Test/execution/show/${jobid}'>Click aqui</a></h3>",
    "name": ["RunDeck"]}' -X POST http://mailer.pro.yapo.cl/api/v1/postfix --header "Content-Type: application/x-www-form-urlencoded" --header "Host: mailer.pro.yapo.cl"
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
