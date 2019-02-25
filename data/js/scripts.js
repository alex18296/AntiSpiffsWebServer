var status_timer = 0;

function to_fry_toast(message, is_error) {
  var x = document.getElementById('toaster');
  if (message) {
    x.innerHTML = message; 
    if ((typeof is_error) == "boolean") {
      if (is_error) {
        x.className = "show error";
      } else {
        x.className = "show success";
      }
    } else {
      x.className = "show";         
    }
    setTimeout(function(){ x.className = x.className.replace('show', ''); }, 3000);
  } else {
    x.className = x.className.replace('show', '');
  }
}

function load_config() {
  $.ajax({
    url: document.location.href + 'config?r=' + Math.random(),
    type: 'GET',
    async: true,
    success: function(data) {
      wait_screen_show(false);
      status_timer = setTimeout(load_device_state, 100);
      if (data) {
        if (data.chk1 && data.chk1 == 'yes') {
          $('#checkbox1').prop('checked', true).change();
        }
        if (data.str1) {
          $("#string1").val(data.str1);
        } else {
          $("#string1").val('');
        }
        if (data.music) {
          $("#music").val(data.music);
        } else {
          $("#music").val('');
        }
        r.setValue(data.r);
        g.setValue(data.g);
        b.setValue(data.b);
      }
    },
    error: function (request, status, error) {
      wait_screen_show(false);
      to_fry_toast('Не удалось загрузить настройки', true);
      //setTimeout(load_config, 10000);
    }
  });
}

var last_journal_record = -1;

function load_device_state() {
  $.ajax({
    url: document.location.href + 'state?r=' + Math.random(),
    type: 'GET',
    async: true,
    success: function(response) {
      status_timer = setTimeout(load_device_state, 2000);
      if (response) {
        if (response.heap) {
          $("#heap").html('' + response.heap);
        } else {
          $("#heap").html('???');
        }
        if (response.journal) {
          var str = '';
          for (var i in response.journal) {
            if (response.journal[i].n > last_journal_record) {
              str += '[' + response.journal[i].n + ']' + response.journal[i].l + '<br/>';
              last_journal_record = response.journal[i].n;
            }
          }
          if (str.length > 0) {
            $("#journal").html($("#journal").html() + str);
          }
        }
      }
    },
    error: function (request, status, error) {
      status_timer = setTimeout(load_device_state, 2000);
    }
  });
}

function save_config() {
  if ( !$("#music").val()) {
    to_fry_toast('Не выбрана музыка', true);
  } else {
    var data = {
      chk1: $('#checkbox1').prop('checked') ? 'yes' : 'no',
      str1: $("#string1").val(),
      music: $("#music").val(),
      r: '' + r.getValue(),
      g: '' + g.getValue(),
      b: '' + b.getValue()
    };
    wait_screen_show(true);
    $.ajax({
      url: document.location.href + 'config',
      type: 'POST',
      data: JSON.stringify(data),
      contentType: 'application/json; charset=utf-8',
      dataType: 'json',
      async: true,
      success: function(response) {
        wait_screen_show(false);
        to_fry_toast('Настройки сохранены', false);
      },
      error: function (request, status, error) {
        wait_screen_show(false);
        to_fry_toast('Не удалось сохранить настройки', true);
      }
    });
    clearTimeout(status_timer);
    status_timer = setTimeout(load_device_state, 1000);
  }
}

var RGBChange = function() {
  $('html, body').css('background', 'rgb(' + r.getValue() + ',' + g.getValue() + ',' + b.getValue() + ')');  
};

var r = $('#R').slider()
    .on('slide', RGBChange)
    .data('slider');
var g = $('#G').slider()
    .on('slide', RGBChange)
    .data('slider');
var b = $('#B').slider()
    .on('slide', RGBChange)
    .data('slider');

function on_load() {
  $('#checkbox1').prop('checked', false).change();
  $('#music').val('');
  $("#string1").val('');
  r.setValue(128);
  g.setValue(128);
  b.setValue(128);
  load_config();
}

function wait_screen_show(e) {
  if (e) {
    $('#main').css('display', 'none');
    $('#wait').css('display', 'block');
  } else {
    $('#main').css('display', 'block');
    $('#wait').css('display', 'none');
  }
}
