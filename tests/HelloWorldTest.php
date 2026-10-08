<?php

require_once __DIR__ . '/../src/hello.php';

class HelloWorldTest extends PHPUnit\Framework\TestCase
{
    public function testOutput()
    {
        ob_start();

        include __DIR__ . '/../src/hello.php';

        $output = ob_get_clean();

        $this->assertEquals("Hello, world!", $output);
    }
}