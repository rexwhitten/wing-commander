# Scheduled Task 

class StartProcessTask {
    [System.String]$name; 

    StartProcessTask([string]$par_name)
    ($this.$name = $par_name)
}