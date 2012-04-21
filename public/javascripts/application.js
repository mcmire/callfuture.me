
(function(window) {

  document.addEventListener('DOMContentLoaded', function() {
    var field = document.getElementById('tz_offset')
    var d = new Date()
    field.value = d.getTimezoneOffset()
  })

})(this)
