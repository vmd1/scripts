sudo rm -f /usr/local/bin/vmd1-sc
echo '#!/bin/bash' | sudo tee /usr/local/bin/vmd1-sc > /dev/null
echo 'curl -sS https://sc.vmd1.dev/l -o /tmp/l > /dev/null 2>&1' | sudo tee -a /usr/local/bin/vmd1-sc > /dev/null
echo 'if [ "$#" -eq 0 ]; then' | sudo tee -a /usr/local/bin/vmd1-sc > /dev/null
echo '  bash /tmp/l' | sudo tee -a /usr/local/bin/vmd1-sc > /dev/null
echo 'else' | sudo tee -a /usr/local/bin/vmd1-sc > /dev/null
echo '  bash /tmp/l "$@"' | sudo tee -a /usr/local/bin/vmd1-sc > /dev/null
echo 'fi' | sudo tee -a /usr/local/bin/vmd1-sc > /dev/null
echo 'rm /tmp/l' | sudo tee -a /usr/local/bin/vmd1-sc > /dev/null
sudo chmod +x /usr/local/bin/vmd1-sc