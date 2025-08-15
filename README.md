wget -qO- https://raw.githubusercontent.com/ClaudioMSJ/Openwrt/refs/heads/main/open.sh | sh


<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Botão de Copiar</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            height: 100vh;
            margin: 0;
            background-color: #f4f4f4;
        }

        .container {
            width: 80%;
            max-width: 600px;
            background-color: #fff;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
        }

        .code-block {
            background-color: #282c34;
            color: #fff;
            padding: 15px;
            border-radius: 6px;
            font-family: 'Courier New', Courier, monospace;
            white-space: pre-wrap;
            position: relative;
        }

        .copy-button {
            background-color: #007bff;
            color: #fff;
            border: none;
            padding: 10px 15px;
            border-radius: 4px;
            cursor: pointer;
            margin-top: 10px;
            font-size: 16px;
            transition: background-color 0.3s ease;
        }

        .copy-button:hover {
            background-color: #0056b3;
        }

        .copy-button:active {
            transform: scale(0.98);
        }
        
        .tooltip {
            visibility: hidden;
            background-color: #555;
            color: #fff;
            text-align: center;
            border-radius: 6px;
            padding: 5px 10px;
            position: absolute;
            z-index: 1;
            bottom: 125%;
            left: 50%;
            margin-left: -60px;
            opacity: 0;
            transition: opacity 0.3s;
        }

        .tooltip.show {
            visibility: visible;
            opacity: 1;
        }

    </style>
</head>
<body>

<div class="container">
    <div class="code-block" id="code-to-copy">
        wget -qO- https://raw.githubusercontent.com/ClaudioMSJ/Openwrt/refs/heads/main/open.sh | sh
    </div>
    <button class="copy-button" onclick="copyCode(this)">Copiar Código</button>
</div>

<script>
    function copyCode(button) {
        const codeBlock = document.getElementById('code-to-copy');
        const textToCopy = codeBlock.innerText;

        // Cria um elemento de texto temporário para a cópia
        const tempTextarea = document.createElement('textarea');
        tempTextarea.value = textToCopy;
        document.body.appendChild(tempTextarea);
        tempTextarea.select();
        document.execCommand('copy');
        document.body.removeChild(tempTextarea);

        // Altera o texto do botão para feedback visual
        const originalText = button.innerText;
        button.innerText = 'Copiado!';

        // Volta ao texto original após 2 segundos
        setTimeout(() => {
            button.innerText = originalText;
        }, 2000);
    }
</script>

</body>
</html>
