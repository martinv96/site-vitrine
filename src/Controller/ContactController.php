<?php
// src/Controller/ContactController.php
namespace App\Controller;

use App\Form\ContactType;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Mailer\MailerInterface;
use Symfony\Component\Mime\Email;
use Symfony\Component\Routing\Annotation\Route;

class ContactController extends AbstractController
{
    #[Route('/contact', name: 'contact')]
    public function index(Request $request, MailerInterface $mailer): Response
    {
        $form = $this->createForm(ContactType::class);
        $form->handleRequest($request);
        $successMessage = null;

        if ($form->isSubmitted() && $form->isValid()) {
            $data = $form->getData();

            $email = (new Email())
                ->from($data['email'])
                ->to($this->getParameter('mailer_to'))
                ->subject('[Contact] ' . $data['subject'])
                ->text(
                    "Nom : " . $data['name'] . "\n" .
                    "Email : " . $data['email'] . "\n\n" .
                    "Message :\n" . $data['message']
                );

            $mailer->send($email);

            $successMessage = "Merci pour votre message, nous vous répondrons rapidement !";
            $form = $this->createForm(ContactType::class); // reset
        }

        return $this->render('contact/index.html.twig', [
            'form' => $form->createView(),
            'successMessage' => $successMessage,
        ]);
    }
}
